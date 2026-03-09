class ApplicationController < ActionController::Base
  include ClerkAuthenticatable
  include AuthPolicy
  include AccessControlHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :set_locale
  helper_method :current_user, :current_local_user, :public_min_reviews, :demo_auto_approve?,
                :submission_email_hmac_pepper, :copy_overall_to_dimensions?,
                :canonical_url, :public_per_page, :public_max_per_page,
                :switch_locale_to, :can_view_details?, :paid_subscriber?

  # A simple struct that provides the duck-typed interface expected by
  # Recruiter#display_name and legacy view code. Wraps the Clerk auth state
  # so views don't need to be rewritten in this change.
  ClerkViewerProxy = Struct.new(:admin?, :paid?) do
    def owner_of_review?(_resource)
      false # Needs clerk_user_id on resources to implement; deferred to follow-up
    end

    def role
      admin? ? "admin" : (paid? ? "paid" : "candidate")
    end
  end

  private

  # Returns the local User record for the authenticated Clerk user, or nil.
  # Used by controllers that need Pay gem methods or other ActiveRecord behavior.
  def current_local_user
    return nil unless authenticated?

    @current_local_user ||= User.find_by(clerk_user_id: auth_service.user_id)
  end

  # Compatibility helper for views still referencing current_user.
  # Returns a ClerkViewerProxy backed by Clerk auth, or nil if not authenticated.
  def current_user
    return nil unless authenticated?

    ClerkViewerProxy.new(
      auth_service.meets_requirements?(:admin),
      paid_subscriber?
    )
  end

  # Returns true if the authenticated Clerk user has the "paid" role in their
  # public metadata. Triggers a cached Clerk API call.
  def paid_subscriber?
    return false unless authenticated?

    clerk.user&.public_metadata&.dig("role") == "paid"
  end

  def set_locale
    # priority: params[:locale] or params[:local] -> cookie -> Accept-Language -> default
    requested = params[:locale].to_s.presence || params[:local].to_s.presence || cookies[:locale].to_s.presence
    allowed = %w[en ja]
    locale = if requested && allowed.include?(requested)
      requested
    else
      header = request.env["HTTP_ACCEPT_LANGUAGE"].to_s
      header&.downcase&.include?("ja") ? :ja : I18n.default_locale
    end
    # Persist selection in a long-lived cookie so subsequent pages honor it
    cookies.permanent[:locale] = locale
    # Use with_locale so the locale is scoped to this request and reset afterwards
    I18n.with_locale(locale) { yield }
  end

  def switch_locale_to(to)
    to = to.to_s
    uri = URI.parse(request.fullpath) rescue nil
    if uri
      q = Rack::Utils.parse_query(uri.query)
      q["locale"] = to
      uri.query = q.to_query
      uri.to_s
    else
      "?locale=#{to}"
    end
  end

  def canonical_url
    base = (ENV["CANONICAL_URL"].presence || request.base_url).to_s
    path = request.fullpath.split("?").first
    File.join(base, path)
  end

  def public_min_reviews
    (ENV["PUBLIC_MIN_REVIEWS"].presence || (Rails.env.development? ? 1 : 5)).to_i
  end

  def public_per_page
    (ENV["PUBLIC_PER_PAGE"].presence || 10).to_i
  end

  def public_max_per_page
    (ENV["PUBLIC_MAX_PER_PAGE"].presence || 50).to_i
  end

  # Paginates +scope+ using params[:page] and params[:per_page].
  # Sets @page, @per_page, @has_next; returns the current page of records.
  def paginate(scope)
    @page = [params[:page].to_i, 1].max
    requested_per = params[:per_page].presence&.to_i
    @per_page = [[requested_per || public_per_page, 1].max, public_max_per_page].min
    offset = (@page - 1) * @per_page
    records = scope.offset(offset).limit(@per_page + 1).to_a
    @has_next = records.length > @per_page
    records.first(@per_page)
  end

  def demo_auto_approve?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_AUTO_APPROVE", Rails.env.development?.to_s))
  end

  def submission_email_hmac_pepper
    ENV.fetch("SUBMISSION_EMAIL_HMAC_PEPPER", "demo-only-pepper-not-secret")
  end

  def copy_overall_to_dimensions?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("SUBMISSION_COPY_OVERALL_TO_DIMENSIONS", "true"))
  end
end
