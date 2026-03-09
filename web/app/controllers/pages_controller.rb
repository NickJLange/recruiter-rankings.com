class PagesController < ApplicationController
  def home
    aggs = Experience.approved_aggregates_by_company
                     .where("recruiters.company_id IS NOT NULL")
                     .order("reviews_count DESC")
                     .limit(10)
    company_ids = aggs.map(&:company_id)
    companies   = Company.where(id: company_ids).index_by(&:id)
    @home_company_stats = aggs.filter_map { |a|
      c = companies[a.company_id]; [c, a.reviews_count] if c
    }
    @top_companies = @home_company_stats.map(&:first)
  end

  def about; end

  def policies; end

  def settings
    require_auth!
  end
end
