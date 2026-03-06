module Admin
  class IdentityVerificationsController < BaseController
    before_action :set_challenge, only: [:approve, :reject, :update]

    def index
      @pending = IdentityChallenge
        .where(verified_at: nil)
        .where("expires_at > ?", Time.current)
        .includes(:subject)
        .order(created_at: :asc)
        .limit(100)
    end

    def approve
      @challenge.update!(verified_at: Time.current)
      @challenge.subject.update!(verified_at: Time.current) if @challenge.subject.respond_to?(:verified_at=)
      ModerationAction.create!(
        actor: current_moderator_actor,
        action: "identity_approve",
        subject: @challenge,
        notes: "subject=#{@challenge.subject_type}##{@challenge.subject_id}"
      )
      redirect_to admin_identity_verifications_path, notice: "Challenge ##{@challenge.id} approved."
    end

    def reject
      ModerationAction.create!(
        actor: current_moderator_actor,
        action: "identity_reject",
        subject: @challenge,
        notes: "subject=#{@challenge.subject_type}##{@challenge.subject_id}"
      )
      @challenge.destroy!
      redirect_to admin_identity_verifications_path, notice: "Challenge rejected and removed."
    end

    def update
      @challenge.update!(challenge_params)
      redirect_to admin_identity_verifications_path, notice: "Challenge ##{@challenge.id} updated."
    end

    private

    def set_challenge
      @challenge = IdentityChallenge.find(params[:id])
    end

    def challenge_params
      params.require(:identity_challenge).permit(:expires_at, :verified_at)
    end
  end
end
