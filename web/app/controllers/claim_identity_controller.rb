class ClaimIdentityController < ApplicationController
  def new
    @subject_type  = params[:subject_type].presence || "recruiter"
    @recruiter_slug = params[:recruiter_slug].to_s
    @recruiter = Recruiter.find_by(public_slug: @recruiter_slug)
  end

  def create
    @subject_type   = params.dig(:claim, :subject_type).to_s
    @recruiter_slug = params.dig(:claim, :recruiter_slug).to_s
    @linkedin_url   = params.dig(:claim, :linkedin_url).to_s

    @recruiter = Recruiter.find_by(public_slug: @recruiter_slug)

    if @subject_type == "recruiter" && @recruiter.nil?
      flash.now[:alert] = "Recruiter not found. Check the slug and try again."
      return render :new, status: :unprocessable_entity
    end

    subject = @recruiter

    # Persist the linkedin_url on the recruiter so admins can check it manually.
    @recruiter.update!(linkedin_url: @linkedin_url) if @recruiter&.linkedin_url.blank? && @linkedin_url.present?

    # Generate a cleartext token to paste into LinkedIn; store its hash for DB uniqueness/lookup.
    raw_token  = SecureRandom.hex(16)
    token_hash = Digest::SHA256.hexdigest(raw_token)
    paste_token = "RR-VERIFY-#{raw_token}"

    challenge = IdentityChallenge.create!(
      subject:    subject,
      token:      paste_token,
      token_hash: token_hash,
      expires_at: 7.days.from_now
    )

    @paste_token  = paste_token
    @challenge_id = challenge.id
    render :instructions
  end

  def verify
    flash[:notice] = "Your claim is in the queue. An admin will verify your LinkedIn profile within 7 days."
    redirect_to root_path
  end
end
