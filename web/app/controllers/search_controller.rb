class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    if @query.length >= 2
      like = "%#{sanitize_sql_like(@query)}%"
      @recruiters = Recruiter.includes(:company).where("name ILIKE ?", like).limit(20)
      @companies  = Company.where("name ILIKE ?", like).limit(10)
    else
      @recruiters = Recruiter.none
      @companies  = Company.none
    end
  end

  private

  def sanitize_sql_like(str)
    str.gsub(/[%_\\]/) { |c| "\\#{c}" }
  end
end
