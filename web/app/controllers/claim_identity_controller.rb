class ClaimIdentityController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'digest'

  protect_from_forgery with: :exception

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

    linkedin_url = params.require(:linkedin_url)
    token = "RR-VERIFY-#{challenge.token_hash}"

    body = linkedin_fetcher.fetch(linkedin_url)
    unless body&.include?(token)
      flash[:alert] = 'Token not found on the page. Make sure it is visible and saved.'
      redirect_to new_claim_identity_path(subject_type: map_subject_param(challenge), recruiter_slug: recruiter_slug_for(challenge), linkedin_url: linkedin_url) and return
    end

    challenge.update!(verified_at: Time.current)

    case challenge.subject_type
    when 'Recruiter'
      recruiter = Recruiter.find(challenge.subject_id)
      recruiter.update!(verified_at: Time.current)
      flash[:notice] = 'Recruiter verified.'
      redirect_to recruiter_path(recruiter.public_slug)
    when 'User'
      flash[:notice] = 'User identity verified.'
      redirect_to root_path
    else
      flash[:notice] = 'Verified.'
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

  def linkedin_fetcher
    @linkedin_fetcher ||= LinkedinFetcher.new
  end

  def hmac_email(email)
    pepper = submission_email_hmac_pepper
    OpenSSL::HMAC.hexdigest('SHA256', pepper, email)
  end

  def find_or_create_user(email)
    email = email.to_s.strip
    email_to_hash = email.presence || "anon-#{SecureRandom.uuid}@example.com"
    hmac = hmac_email(email_to_hash)
    User.where(email_hmac: hmac).first_or_create! do |u|
      u.role = 'recruiter'
      u.email_kek_id = 'demo'
    end
  end
end

