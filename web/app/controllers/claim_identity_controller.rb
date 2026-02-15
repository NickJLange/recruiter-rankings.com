class ClaimIdentityController < ApplicationController
  require 'digest'

  attr_writer :linkedin_fetcher

  def linkedin_fetcher
    @linkedin_fetcher ||= LinkedInFetcher.new
  end

  def new
    @subject_type = params[:subject_type].presence || 'recruiter'
    @recruiter_slug = params[:recruiter_slug].to_s
    @linkedin_url = params[:linkedin_url].to_s
    @email = params[:email].to_s
  end

  # Creates an identity challenge and shows instructions
  def create
    @subject_type = permitted[:subject_type]
    @linkedin_url = permitted[:linkedin_url]
    @recruiter_slug = permitted[:recruiter_slug]
    @email = permitted[:email]

    case @subject_type
    when 'recruiter'
      recruiter = Recruiter.find_by!(public_slug: @recruiter_slug)
      subject = recruiter
    when 'user'
      user = find_or_create_user(@email)
      user.update!(linked_in_url: @linkedin_url) if @linkedin_url.present?
      subject = user
    else
      raise ActionController::BadRequest, 'Invalid subject_type'
    end

    token_hash = generate_token_hash
    ttl_hours = (ENV['CLAIM_TTL_HOURS'].presence || '168').to_i
    challenge = IdentityChallenge.create!(
      subject_type: subject.class.name,
      subject_id: subject.id,
      token_hash: token_hash,
      linkedin_url: @linkedin_url,
      expires_at: ttl_hours.hours.from_now
    )

    @challenge_id = challenge.id
    @paste_token = "RR-VERIFY-#{token_hash}"
    @instructions = [
      'Copy the token below',
      'Paste it into your LinkedIn profile (About, Featured, or Website)',
      'Return and click Verify'
    ]

    render :instructions
  end

  # Fetches the LinkedIn URL and checks for the token
  def verify
    challenge = IdentityChallenge.find(params.require(:challenge_id))
    raise ActionController::BadRequest, 'Expired' if challenge.expires_at.past?

    # Security Fix: Use stored URL instead of user input to prevent account takeover
    linkedin_url = challenge.linkedin_url
    if linkedin_url.blank?
      # Fallback for old challenges or missing data - though we should probably require it.
      # For security, we should reject if not present, but for now we might error.
      # Let's check params if missing in DB for backward compat? No, that re-opens the hole.
      # We must rely on the DB.
      flash[:alert] = 'Invalid challenge data.'
      redirect_to root_path and return
    end

    token = "RR-VERIFY-#{challenge.token_hash}"

    VerifyIdentityJob.perform_later(challenge.id, linkedin_url)

    flash[:notice] = 'Verification is running in the background. Please check back in a moment.'

    case challenge.subject_type
    when 'Recruiter'
      recruiter = Recruiter.find(challenge.subject_id)
      redirect_to recruiter_path(recruiter.public_slug)
    else
      redirect_to root_path
    end
  end

  private

  def map_subject_param(challenge)
    challenge.subject_type.downcase
  end

  def recruiter_slug_for(challenge)
    return nil unless challenge.subject_type == 'Recruiter'
    Recruiter.find(challenge.subject_id).public_slug
  end

  def permitted
    params.require(:claim).permit(:subject_type, :recruiter_slug, :linkedin_url, :email)
  end

  def generate_token_hash
    raw = SecureRandom.hex(16) # 128-bit
    Digest::SHA256.hexdigest(raw)
  end

  def find_or_create_user(email)
    email = email.to_s.strip
    email_to_hash = email.presence || "anon-#{SecureRandom.uuid}@example.com"
    hmac = User.generate_email_hmac(email_to_hash)
    User.where(email_hmac: hmac).first_or_create! do |u|
      u.role = 'recruiter'
      u.email_kek_id = 'demo'
    end
  end
end

