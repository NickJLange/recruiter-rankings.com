# Test-only middleware that injects a fake Clerk::Proxy into request.env['clerk']
# when ClerkTestHelper#sign_in_as_clerk has been called.
#
# Two session stores:
#   Thread.current[:fake_clerk]   — integration tests (rack-test, same thread as server)
#   @@sessions[cookie_key]        — system tests (real browser, different thread)
#
# Loaded in config/initializers/test_clerk_middleware.rb, replacing Clerk::Rack::Middleware
# in the test environment so JWT verification is skipped entirely.
class FakeClerkMiddleware
  @sessions = {}
  @mutex = Mutex.new

  class << self
    def store_session(key, mock)
      @mutex.synchronize { @sessions[key] = mock }
    end

    def clear_session(key)
      @mutex.synchronize { @sessions.delete(key) }
    end

    def fetch_session(key)
      @mutex.synchronize { @sessions[key] }
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    # Integration tests: thread-local takes priority
    fake = Thread.current[:fake_clerk]

    # System tests: look up session by _clerk_test_key cookie set by the test
    if fake.nil?
      req = Rack::Request.new(env)
      test_key = req.cookies["_clerk_test_key"]
      fake = FakeClerkMiddleware.fetch_session(test_key) if test_key&.present?
    end

    env["clerk"] = fake if fake
    @app.call(env)
  end
end
