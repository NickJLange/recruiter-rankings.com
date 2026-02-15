class CompaniesController < ApplicationController
  def index
    threshold = public_min_reviews
    aggregates = Experience.where(status: "approved")
      .joins(interaction: :recruiter)
      .group("recruiters.company_id")
      .select("recruiters.company_id as company_id, COUNT(*) AS reviews_count, AVG(rating) AS avg_overall")

    scope = Company
      .joins("INNER JOIN (#{aggregates.to_sql}) agg ON agg.company_id = companies.id")
      .where("agg.reviews_count >= ?", threshold)
      .select("companies.*, agg.reviews_count, agg.avg_overall")

    # Filters
    @q = params[:q].to_s.strip
    @region = params[:region].to_s.strip
    @type = params[:type].to_s.strip

    if @q.present?
      scope = scope.where("companies.name ILIKE ?", "%#{@q}%")
    end
    if @region.present?
      scope = scope.where("companies.region ILIKE ?", "%#{@region}%")
    end
    if @type == "recruiting"
      # Companies that have acted as recruiting agencies (recruiting_roles)
      scope = scope.where(id: Role.select(:recruiting_company_id))
    elsif @type == "hiring"
      # Companies that have been hired for (target_roles)
      scope = scope.where(id: Role.select(:target_company_id))
    end

    scope = scope.order("agg.avg_overall DESC NULLS LAST, companies.name ASC")

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
    overall = Experience.where(status: "approved")
      .joins(interaction: :recruiter)
      .where(recruiters: { company_id: @company.id })
      .pluck(Arel.sql("COUNT(*), AVG(rating)"))
      .first || [0, nil]
    @reviews_count = overall[0]
    @avg_overall = overall[1]&.to_f

    # Recruiters under this company with aggregates
    # Recruiters under this company with aggregates
    if can_view_details?
      aggregates = Experience.where(status: "approved")
        .joins(:interaction)
        .group("interactions.recruiter_id")
        .select("interactions.recruiter_id, COUNT(*) AS reviews_count, AVG(rating) AS avg_overall")

      @recruiters = Recruiter.where(company: @company)
        .joins("LEFT JOIN (#{aggregates.to_sql}) agg ON agg.recruiter_id = recruiters.id")
        .select("recruiters.*, COALESCE(agg.reviews_count, 0) AS reviews_count, agg.avg_overall")
        .order("agg.avg_overall DESC NULLS LAST, recruiters.name ASC")
    else
      # Anonymous: Aggregate Trendline by Role
      # Group by Quarter and Role Title
      raw_data = Experience.where(status: "approved")
        .joins(interaction: [:role, :recruiter])
        .where(recruiters: { company_id: @company.id })
        .group("DATE_TRUNC('quarter', interactions.occurred_at)", "roles.title")
        .average(:rating)

      # Transform for Chart.js
      # Labels: Quarters (sorted)
      # Datasets: One per Role Title
      
      # { [date, title] => rating }
      dates = raw_data.keys.map(&:first).uniq.sort
      titles = raw_data.keys.map(&:last).uniq.sort

      @chart_labels = dates.map { |d| d.strftime("Q%q %Y") }
      
      @chart_datasets = titles.map do |title|
        data_points = dates.map do |date|
          # Find rating for this date/title, round to 2 decimals
          rating = raw_data[[date, title]]
          rating ? rating.to_f.round(2) : nil
        end
        
        # Consistent color generation based on title string
        color_hash = Digest::MD5.hexdigest(title)[0..5]
        color = "##{color_hash}"

        {
          label: title,
          data: data_points,
          borderColor: color,
          backgroundColor: color,
          fill: false,
          tension: 0.1
        }
      end
    end
  end

  private

  def can_view_details?
    return true if current_user&.admin?
    return true if current_user&.paid?
    # TODO: Add logic for 'owner_of_review?' if checking specific recruiter
    false
  end
  helper_method :can_view_details?
end
