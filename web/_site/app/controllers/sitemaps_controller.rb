class SitemapsController < ApplicationController
  protect_from_forgery with: :null_session

  def show
    @canonical = canonical_base_url
    @static_paths = [
      "",
      "/about",
      "/policies",
      "/recruiters"
    ]
    @recruiters = Recruiter.order(updated_at: :desc).select(:public_slug, :updated_at)
    respond_to do |format|
      format.xml
    end
  end

  private

  def canonical_base_url
    (ENV["CANONICAL_URL"].presence || request.base_url).to_s
  end
end

