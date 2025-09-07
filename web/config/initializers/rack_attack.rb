class Rack::Attack
  # Use a simple keyed cache. Render will set RACK_ATTACK_REDIS_URL if you add Redis; but we use in-memory by default.
  # throttle review submissions per IP
  throttle("reviews/ip", limit: (ENV["RATE_LIMIT_REVIEWS_PER_MIN"] || 10).to_i, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/reviews"
  end

  # throttle claim identity create/verify per IP
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

Rails.application.config.middleware.use Rack::Attack
