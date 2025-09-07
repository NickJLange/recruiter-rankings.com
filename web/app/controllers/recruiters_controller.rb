class RecruitersController < ApplicationController
  def index
    threshold = public_min_reviews

    aggregates = Review.where(status: "approved")
      .group(:recruiter_id)
      .select(:recruiter_id, "COUNT(*) AS reviews_count", "AVG(overall_score) AS avg_overall")

    scope = Recruiter
      .joins("INNER JOIN (#{aggregates.to_sql}) agg ON agg.recruiter_id = recruiters.id")
      .left_joins(:company)
      .where("agg.reviews_count >= ?", threshold)

    # Filters
    @q = params[:q].to_s.strip
    @company = params[:company].to_s.strip
    @region = params[:region].to_s.strip

    if @q.present?
      scope = scope.where("recruiters.name ILIKE ?", "%#{@q}%")
    end
    if @company.present?
      scope = scope.where("companies.name ILIKE ?", "%#{@company}%")
    end
    if @region.present?
      scope = scope.where("(recruiters.region ILIKE ? OR companies.region ILIKE ?)", "%#{@region}%", "%#{@region}%")
    end

    scope = scope.select("recruiters.*, agg.reviews_count, agg.avg_overall")
                 .order("agg.avg_overall DESC NULLS LAST, recruiters.name ASC")

    # Pagination (fetch one extra to know if there is a next page)
    @page = params[:page].to_i
    @page = 1 if @page < 1
    requested_per = params[:per_page].presence&.to_i
    @per_page = [[requested_per || public_per_page, 1].max, public_max_per_page].min

    offset = (@page - 1) * @per_page
    records = scope.offset(offset).limit(@per_page + 1).to_a
    @has_next = records.length > @per_page
    @recruiters = records.first(@per_page)

    respond_to do |format|
      format.html
      format.json do
        render json: @recruiters.map { |r|
          {
            name: r.name,
            slug: r.public_slug,
            company: r.company&.name,
            region: r.region,
            reviews_count: r.attributes['reviews_count'].to_i,
            avg_overall: r.attributes['avg_overall']&.to_f
          }
        }
      end
    end
  end

  def show
    @recruiter = Recruiter.find_by!(public_slug: params[:slug])

    @reviews = @recruiter.reviews.where(status: "approved").order(created_at: :desc).limit(25)

    # Overall aggregates
    overall = @recruiter.reviews.where(status: "approved")
      .pluck(Arel.sql("COUNT(*), AVG(overall_score)"))
      .first || [0, nil]
    @reviews_count = overall[0]
    @avg_overall = overall[1]&.to_f

    # Dimension aggregates
    dims = ReviewMetric.where(review_id: @recruiter.reviews.where(status: "approved"))
      .group(:dimension)
      .pluck(:dimension, Arel.sql("AVG(score)"))
    @dimension_averages = dims.to_h

    respond_to do |format|
      format.html
      format.json do
        render json: {
          name: @recruiter.name,
          slug: @recruiter.public_slug,
          company: @recruiter.company&.name,
          region: @recruiter.region,
          reviews_count: @reviews_count,
          avg_overall: @avg_overall,
          dimensions: @dimension_averages
        }
      end
    end
  end
end

