class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  helper_method :public_min_reviews, :demo_auto_approve?, :submission_email_hmac_pepper, :copy_overall_to_dimensions?, :canonical_url, :public_per_page, :public_max_per_page, :switch_locale_to

  private

  def set_locale
    # priority: params[:locale] -> Accept-Language -> default
    requested = params[:locale].to_s.presence
    allowed = %w[en ja]
    if requested && allowed.include?(requested)
      I18n.locale = requested
    else
      header = request.env["HTTP_ACCEPT_LANGUAGE"].to_s
      I18n.locale = header&.downcase&.include?("ja") ? :ja : I18n.default_locale
    end
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
