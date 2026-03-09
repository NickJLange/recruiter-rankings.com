# In test environment, replace the real Clerk JWT middleware with a fake injector
# that reads from ClerkTestHelper#sign_in_as_clerk's thread-local state.
# This prevents tests from needing valid Clerk tokens and lets tests exercise
# the full auth policy logic with mocked identities.
if Rails.env.test?
  require_relative "../../lib/fake_clerk_middleware"
  Rails.application.config.middleware.swap(
    Clerk::Rack::Middleware,
    FakeClerkMiddleware
  )
end
