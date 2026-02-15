module Admin
  class ReviewsController < ApplicationController
    before_action :require_moderator_auth
    before_action :set_review, only: [:approve, :flag, :remove]

    # List reviews to moderate (pending + flagged by default)
    def index
      @statuses = params[:statuses].present? ? params[:statuses].split(",") : ["pending", "flagged"]
      @reviews = Review.where(status: @statuses)
        .includes(:recruiter, :company, :review_responses)
        .order(created_at: :desc)
        .limit((params[:limit] || 100).to_i)
    end

    def approve
      transition!(@review, "approved")
    end

    def flag
      transition!(@review, "flagged")
    end

    def remove
      transition!(@review, "removed")
    end

    private

    def transition!(review, new_status)
      old = review.status
      review.update!(status: new_status)
      ModerationAction.create!(actor: current_moderator_actor, action: "set_status:#{new_status}", subject: review, notes: "from: #{old}")
      redirect_to admin_reviews_path, notice: "Review ##{review.id} set to #{new_status}."
    end

    def set_review
      @review = Review.find(params[:id])
    end

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

    # CSRF: our forms include tokens; for API-style PATCH via curl, you can disable below (kept enabled for demo UI)
    protect_from_forgery with: :exception
  end
end
