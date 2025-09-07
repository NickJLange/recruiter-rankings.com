class RevealsController < ApplicationController
  include RecruitersHelper

  def new
    @linkedin_url = params[:linkedin_url].to_s
    @email = params[:email].to_s
    @company = params[:company].to_s
  end

  def create
    # Enforce simple per-day cap in app (supplemented by Rack::Attack IP limit)
    if reveals_today_count >= reveals_daily_limit
      flash[:alert] = 'Daily reveal limit reached.'
      redirect_to new_reveal_path and return
    end

    recruiter = nil

    email = params[:email].to_s.strip
    if email.present?
      hmac = OpenSSL::HMAC.hexdigest('SHA256', submission_email_hmac_pepper, email)
      recruiter = Recruiter.find_by(email_hmac: hmac)
    end

    if recruiter.nil?
      li = params[:linkedin_url].to_s.strip.downcase
      if li.present?
        recruiter = Recruiter.where('LOWER(linkedin_url) = ?', li).first
      end
    end

    if recruiter.nil?
      flash[:alert] = 'No matching recruiter found.'
      redirect_to new_reveal_path and return
    end

    company = params[:company].to_s.strip
    if company.present?
      unless recruiter.company&.name&.downcase&.include?(company.downcase)
        flash[:alert] = 'Company did not match that recruiter.'
        redirect_to new_reveal_path and return
      end
    end

    add_revealed_recruiter!(recruiter.id)
    increment_reveals_today!
    flash[:notice] = 'Recruiter revealed for you.'
    redirect_to recruiter_path(recruiter.public_slug)
  end
end
