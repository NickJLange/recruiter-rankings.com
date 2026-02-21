module Admin
  class ResponsesController < BaseController
    def create
      review = Review.find(params[:review_id])
      body = params.require(:review_response).permit(:body)[:body]
      raise ActionController::BadRequest, "Empty body" if body.blank?

      resp = ReviewResponse.create!(review: review, user: current_moderator_actor, body: body, visible: true)
      ModerationAction.create!(actor: current_moderator_actor, action: "respond", subject: review, notes: "response_id=#{resp.id}")
      redirect_to admin_reviews_path, notice: "Response posted for review ##{review.id}."
    end

    def hide
      resp = ReviewResponse.find(params[:id])
      resp.update!(visible: false)
      ModerationAction.create!(actor: current_moderator_actor, action: "response_hide", subject: resp.review, notes: "response_id=#{resp.id}")
      redirect_to admin_reviews_path, notice: "Response hidden."
    end

    def unhide
      resp = ReviewResponse.find(params[:id])
      resp.update!(visible: true)
      ModerationAction.create!(actor: current_moderator_actor, action: "response_show", subject: resp.review, notes: "response_id=#{resp.id}")
      redirect_to admin_reviews_path, notice: "Response visible."
    end
  end
end
