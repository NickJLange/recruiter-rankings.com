module Admin
  class ResponsesController < ApplicationController
    before_action :require_moderator_auth

    def create
      review = Review.find(params[:review_id])
      body = params.require(:review_response).permit(:body)[:body]
      raise ActionController::BadRequest, "Empty body" if body.blank?

      resp = ReviewResponse.create!(review: review, user: current_moderator_actor, body: body)
      ModerationAction.create!(actor: current_moderator_actor, action: "respond", subject: review, notes: "response_id=#{resp.id}")
      redirect_to admin_reviews_path, notice: "Response posted for review ##{review.id}."
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
