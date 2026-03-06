# Thin adapter over the Clerk SDK. All Clerk-specific calls live here —
# swap this file if we ever change identity providers.
class AuthenticationService
  # Which connected accounts each policy requires.
  PROVIDER_REQUIREMENTS = {
    candidate_submit: { any_of: [:email, :linkedin] },
    candidate_paid:   { all_of: [:email, :linkedin] },
    recruiter:        { all_of: [:linkedin] },
    admin:            { all_of: [:email, :linkedin, :github], two_factor: true }
  }.freeze

  def initialize(clerk_helper)
    @clerk = clerk_helper
  end

  # Uses JWT claims only — no API call.
  def authenticated?
    @clerk&.user_id.present?
  end

  def user_id
    @clerk&.user_id
  end

  def session_claims
    @clerk&.session
  end

  # Checks whether the user has a given connected provider.
  # Triggers a cached Backend API call (60s TTL via Rails.cache).
  def has_provider?(provider)
    return false unless authenticated?

    case provider
    when :email
      clerk_user.email_addresses.any? { |e| e.verification&.status == "verified" }
    when :linkedin, :github
      clerk_user.external_accounts.any? { |a| a.provider == provider.to_s }
    else
      false
    end
  end

  # Reads from the cached full user object — API call required.
  def two_factor_enabled?
    return false unless authenticated?

    clerk_user.two_factor_enabled
  end

  def meets_requirements?(policy_key)
    # Dev-only escape hatch: set BYPASS_ADMIN_PROVIDERS=true to skip provider/2FA checks.
    # Never set this in production — the env var is ignored outside development.
    if policy_key == :admin &&
        !Rails.env.production? &&
        ActiveModel::Type::Boolean.new.cast(ENV.fetch("BYPASS_ADMIN_PROVIDERS", "false"))
      return authenticated?
    end

    reqs = PROVIDER_REQUIREMENTS.fetch(policy_key)

    providers_met = if reqs[:any_of]
      reqs[:any_of].any? { |p| has_provider?(p) }
    elsif reqs[:all_of]
      reqs[:all_of].all? { |p| has_provider?(p) }
    end

    two_factor_met = reqs[:two_factor] ? two_factor_enabled? : true

    providers_met && two_factor_met
  end

  private

  def clerk_user
    @clerk_user ||= @clerk.user
  end
end
