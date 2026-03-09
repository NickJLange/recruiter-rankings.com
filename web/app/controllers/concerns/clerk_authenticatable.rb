module ClerkAuthenticatable
  extend ActiveSupport::Concern

  included do
    # Pull in the Clerk SDK concern — provides the `clerk` helper method
    # that reads the Clerk::Proxy set by Clerk::Rack::Middleware.
    include Clerk::Authenticatable

    helper_method :auth_service, :current_clerk_user, :authenticated?
  end

  protected

  def auth_service
    @auth_service ||= AuthenticationService.new(clerk)
  end

  # Alias for use in views/templates — returns the AuthenticationService.
  def current_clerk_user
    auth_service
  end

  def authenticated?
    auth_service.authenticated?
  end

  def require_auth!
    return if authenticated?

    sign_in_url = clerk&.sign_in_url.presence || root_path
    redirect_to sign_in_url, allow_other_host: true
  end
end
