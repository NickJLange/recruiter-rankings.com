clerk_secret_key = ENV["CLERK_SECRET_KEY"] ||
                   Rails.application.credentials.dig(:clerk, :secret_key)

clerk_publishable_key = ENV["CLERK_PUBLISHABLE_KEY"] ||
                        Rails.application.credentials.dig(:clerk, :publishable_key)

if clerk_secret_key.blank? && Rails.env.production?
  raise "CLERK_SECRET_KEY is not set. Add it to the Render dashboard under " \
        "Environment → Secret Variables, or to Rails credentials via `rails credentials:edit`."
end

if clerk_secret_key.present?
  Clerk.configure do |config|
    config.secret_key = clerk_secret_key
    config.publishable_key = clerk_publishable_key

    # Exclude routes where Clerk middleware overhead is unnecessary and no auth check
    # is ever performed. Content pages (recruiter show, company pages) are NOT excluded
    # because can_view_details? needs to read the Clerk session.
    config.excluded_routes = [
      "/up",
      "/sitemap.xml",
      "/favicon.ico",
      "/assets/"
    ]
  end
end

# Derive the Clerk frontend API URL from the publishable key so ClerkJS can be
# loaded from the correct instance CDN. Format: pk_(test|live)_BASE64 where
# Base64 decodes to "subdomain.clerk.accounts.dev$" (trailing $ is a checksum).
Rails.application.config.clerk_js_url = begin
  key = ENV["CLERK_PUBLISHABLE_KEY"].to_s
  if key.present?
    encoded = key.split("_").last
    domain = Base64.decode64(encoded).delete_suffix("$")
    "https://#{domain}/npm/@clerk/clerk-js@latest/dist/clerk.browser.js"
  end
end
