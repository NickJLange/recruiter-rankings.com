class CompaniesController < ApplicationController
  def index
    threshold = public_min_reviews
    aggregates = Review.where(status: "approved").group(:company_id).select(:company_id, "COUNT(*) AS reviews_count", "AVG(overall_score) AS avg_overall")

    scope = Company
      .joins("INNER JOIN (#{aggregates.to_sql}) agg ON agg.company_id = companies.id")
      .where("agg.reviews_count >= ?", threshold)
      .select("companies.*, agg.reviews_count, agg.avg_overall")

    # Filters
    @q = params[:q].to_s.strip
    @region = params[:region].to_s.strip
    if @q.present?
      scope = scope.where("companies.name ILIKE ?", "%#{@q}%")
    end
    if @region.present?
      scope = scope.where("companies.region ILIKE ?", "%#{@region}%")
    end

    scope = scope.order(Arel.sql("agg.avg_overall DESC NULLS LAST, companies.name ASC"))

    # Pagination
    @page = params[:page].to_i; @page = 1 if @page < 1
    requested_per = params[:per_page].presence&.to_i
    @per_page = [[requested_per || public_per_page, 1].max, public_max_per_page].min
    offset = (@page - 1) * @per_page
    records = scope.offset(offset).limit(@per_page + 1).to_a
    @has_next = records.length > @per_page
    @companies = records.first(@per_page)

    respond_to do |format|
      format.html
      format.json do
        expires_in 30.minutes, public: true
        per = (params[:per].presence || 5).to_i
        render json: scope.limit(per).map { |c|
          { id: c.id, name: c.name, reviews_count: c.attributes['reviews_count'].to_i, avg_overall: c.attributes['avg_overall']&.to_f }
        }
      end
    end
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
