module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    # Returns the local User record for the currently authenticated admin,
    # looked up by Clerk user ID. Used for ModerationAction audit logging.
    # Returns nil if no matching local record exists (optional on ModerationAction).
    def current_moderator_actor
      @current_moderator_actor ||= User.find_by(clerk_user_id: auth_service.user_id)
    end
  end
end
