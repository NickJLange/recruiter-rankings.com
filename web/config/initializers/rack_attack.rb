class Rack::Attack
  # Use a simple keyed cache. Render will set RACK_ATTACK_REDIS_URL if you add Redis; but we use in-memory by default.

  # Throttle review submissions: by Clerk user ID when authenticated, IP otherwise.
  throttle("reviews/user_or_ip", limit: (ENV["RATE_LIMIT_REVIEWS_PER_MIN"] || 10).to_i, period: 1.minute) do |req|
    if req.post? && req.path == "/reviews"
      req.env.dig("clerk")&.user_id || req.ip
    end
  end

  # Throttle recruiter creation: by Clerk user ID when authenticated, IP otherwise.
  throttle("recruiters/user_or_ip", limit: (ENV["RATE_LIMIT_RECRUITERS_PER_HOUR"] || 10).to_i, period: 1.hour) do |req|
    if req.post? && req.path == "/person"
      req.env.dig("clerk")&.user_id || req.ip
    end
  end

  # Throttle claim identity create/verify per IP (unauthenticated flow).
  throttle("claim/ip", limit: (ENV["RATE_LIMIT_CLAIM_PER_MIN"] || 10).to_i, period: 1.minute) do |req|
    if req.post? && (req.path == "/claim_identity" || req.path == "/claim_identity/verify")
      req.ip
    end
  end

  # Basic safelist for healthchecks
  safelist("healthcheck") do |req|
    req.get? && req.path == "/up"
  end
end
