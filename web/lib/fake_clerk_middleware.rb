# Test-only middleware that injects a fake Clerk::Proxy into request.env['clerk']
# when ClerkTestHelper#sign_in_as_clerk has been called.
#
# Loaded in config/environments/test.rb and prepended before Clerk::Rack::Middleware
# so the real middleware sees env['clerk'] already set and skips JWT verification.
class FakeClerkMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if (fake = Thread.current[:fake_clerk])
      env['clerk'] = fake
    end
    @app.call(env)
  end
end
