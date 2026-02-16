module Admin
  class BaseController < ApplicationController
    before_action :require_moderator_auth

    private

    def require_moderator_auth
      expected_user = ENV["DEMO_MOD_USER"].presence || "mod"
      expected_pass = ENV["DEMO_MOD_PASSWORD"].presence || "mod"
      authenticate_or_request_with_http_basic("Moderation") do |u, p|
        ActiveSupport::SecurityUtils.secure_compare(u, expected_user) &&
          ActiveSupport::SecurityUtils.secure_compare(p, expected_pass)
      end
    end

    def current_moderator_actor
      @current_moderator_actor ||= User.find_by(role: "moderator")
    end
  end
end
