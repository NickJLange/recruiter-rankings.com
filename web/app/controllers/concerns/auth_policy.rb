module AuthPolicy
  extend ActiveSupport::Concern

  private

  # Enforces a named policy from AuthenticationService::PROVIDER_REQUIREMENTS.
  # Redirects to sign-in if not authenticated; redirects home with an alert
  # if authenticated but missing required providers/2FA.
  def require_policy!(policy_key)
    require_auth!
    return if performed?

    unless auth_service.meets_requirements?(policy_key)
      redirect_to root_path,
        alert: "Please connect the required accounts in your profile to continue."
    end
  end

  def require_admin!
    require_policy!(:admin)
  end
end
