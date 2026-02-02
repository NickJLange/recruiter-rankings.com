class RecruitersController < ApplicationController
  def index
    threshold = public_min_reviews

    aggregates = Experience.where(status: "approved")
      .joins(:interaction)
      .group("interactions.recruiter_id")
      .select("interactions.recruiter_id, COUNT(*) AS reviews_count, AVG(rating) AS avg_overall")

    scope = Recruiter
      .joins("INNER JOIN (#{aggregates.to_sql}) agg ON agg.recruiter_id = recruiters.id")
      .left_joins(:company)
      .preload(:company)
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
    @recruiter = Recruiter.includes(:company).find_by!(public_slug: params[:slug])
    
    # Access Control
    @can_view_details = current_user && (
      current_user.admin? || 
      current_user.paid? || 
      current_user.owner_of_review?(@recruiter)
    )

    # Base scope for approved experiences
    base_scope = Experience.where(status: "approved")
      .joins(:interaction)
      .where(interactions: { recruiter_id: @recruiter.id })

    # Overall aggregates (visible to all)
    overall = base_scope.pluck(Arel.sql("COUNT(*), AVG(rating)")).first || [0, nil]
    @reviews_count = overall[0]
    @avg_overall = overall[1]&.to_f

    # Dimensional aggregates
    @dimensional_averages = ReviewMetric
      .joins(:experience)
      .merge(base_scope)
      .group(:dimension)
      .average(:score)

    if @can_view_details
      # Load full reviews
      @reviews = base_scope.order("interactions.occurred_at DESC").limit(50)
    else
      # Load quarterly aggregates only
      # Postgres-specific median calculation
      @quarterly_aggregates = base_scope
        .group("DATE_TRUNC('quarter', interactions.occurred_at)")
        .order(Arel.sql("DATE_TRUNC('quarter', interactions.occurred_at) DESC"))
        .pluck(
          Arel.sql("DATE_TRUNC('quarter', interactions.occurred_at) AS quarter"),
          Arel.sql("COUNT(*) as count"),
          Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rating) as median")
        )
    end

    respond_to do |format|
      format.html
      format.json do
        payload = {
          name: @recruiter.name,
          slug: @recruiter.public_slug,
          company: @recruiter.company&.name,
          region: @recruiter.region,
          reviews_count: @reviews_count,
          avg_overall: @avg_overall,
          dimensional_averages: @dimensional_averages
        }
        
        if @can_view_details
          payload[:reviews] = @reviews.map { |r| 
            {
              id: r.id,
              rating: r.rating,
              body: r.body,
              occurred_at: r.interaction.occurred_at
            }
          }
        else
          payload[:quarterly] = @quarterly_aggregates.map { |q, c, m| { quarter: q, count: c, median: m } }
        end
        
        render json: payload
      end
    end
  end
end

