class CompaniesController < ApplicationController
  def index
    threshold = public_min_reviews
    aggregates = Review.where(status: "approved").group(:company_id).select(:company_id, "COUNT(*) AS reviews_count", "AVG(overall_score) AS avg_overall")

    @companies = Company
      .joins("INNER JOIN (#{aggregates.to_sql}) agg ON agg.company_id = companies.id")
      .where("agg.reviews_count >= ?", threshold)
      .select("companies.*, agg.reviews_count, agg.avg_overall")
      .order("agg.avg_overall DESC NULLS LAST, companies.name ASC")
  end

  def show
    @company = Company.find(params[:id])

    # Company aggregates
    overall = Review.where(company: @company, status: "approved").pluck(Arel.sql("COUNT(*), AVG(overall_score)")).first || [0, nil]
    @reviews_count = overall[0]
    @avg_overall = overall[1]&.to_f

    # Recruiters under this company with aggregates
    aggregates = Review.where(status: "approved").group(:recruiter_id).select(:recruiter_id, "COUNT(*) AS reviews_count", "AVG(overall_score) AS avg_overall")
    @recruiters = Recruiter.where(company: @company)
      .joins("LEFT JOIN (#{aggregates.to_sql}) agg ON agg.recruiter_id = recruiters.id")
      .select("recruiters.*, COALESCE(agg.reviews_count, 0) AS reviews_count, agg.avg_overall")
      .order("agg.avg_overall DESC NULLS LAST, recruiters.name ASC")
  end
end
