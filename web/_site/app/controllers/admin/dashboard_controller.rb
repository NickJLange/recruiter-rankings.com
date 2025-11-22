module Admin
  class DashboardController < ApplicationController
    before_action :require_moderator_auth

    def index
      @pending_count = Review.where(status: "pending").count
      @flagged_count = Review.where(status: "flagged").count
      @hidden_responses_count = ReviewResponse.where(visible: false).count
      @recent_submissions_24h = Review.where("created_at >= ?", 24.hours.ago).count
      @verification_backlog = IdentityChallenge.where(verified_at: nil).count
      @recent_actions = ModerationAction.order(created_at: :desc).limit(20)
    end

    private

    def current_moderator_actor
      User.find_by(role: "moderator")
    end

    def require_moderator_auth
      expected_user = ENV["DEMO_MOD_USER"].presence || "mod"
      expected_pass = ENV["DEMO_MOD_PASSWORD"].presence || "mod"
      authenticate_or_request_with_http_basic("Moderation") do |u, p|
        ActiveSupport::SecurityUtils.secure_compare(u, expected_user) &&
          ActiveSupport::SecurityUtils.secure_compare(p, expected_pass)
      end
    end
  end
end
