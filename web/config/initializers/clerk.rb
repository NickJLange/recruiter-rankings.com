Clerk.configure do |config|
  config.secret_key = ENV["CLERK_SECRET_KEY"]
  config.publishable_key = ENV["CLERK_PUBLISHABLE_KEY"]

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
