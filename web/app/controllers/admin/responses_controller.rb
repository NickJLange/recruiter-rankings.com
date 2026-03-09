module Admin
  class ResponsesController < Admin::BaseController
    def create
      review = Review.find(params[:review_id])
      body = params.require(:review_response).permit(:body)[:body]
      raise ActionController::BadRequest, "Empty body" if body.blank?

      resp = ReviewResponse.create!(review: review, user: current_local_user, body: body, visible: true)
      log_moderation("respond", review, "response_id=#{resp.id}")
      redirect_to admin_reviews_path, notice: "Response posted for review ##{review.id}."
    end

    def hide
      set_response_visibility(false)
    end

    def unhide
      set_response_visibility(true)
    end

    private

    def set_response_visibility(visible)
      resp = ReviewResponse.find(params[:id])
      resp.update!(visible: visible)
      log_moderation(visible ? "response_show" : "response_hide", resp.review, "response_id=#{resp.id}")
      redirect_to admin_reviews_path, notice: "Response #{visible ? 'visible' : 'hidden'}."
    end

  end
end
