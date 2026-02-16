module Admin
  class DashboardController < BaseController
    def index
      @pending_count = Review.where(status: "pending").count
      @flagged_count = Review.where(status: "flagged").count
      @hidden_responses_count = ReviewResponse.where(visible: false).count
      @recent_submissions_24h = Review.where("created_at >= ?", 24.hours.ago).count
      @verification_backlog = IdentityChallenge.where(verified_at: nil).count
      @recent_actions = ModerationAction.order(created_at: :desc).limit(20)
    end
  end
end
