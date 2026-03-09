module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def log_moderation(action, subject, notes = nil)
      ModerationAction.create!(actor: current_local_user, action: action, subject: subject, notes: notes)
    end
  end
end
