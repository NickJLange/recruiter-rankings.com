class RecruitersController < ApplicationController
  def index
    threshold = public_min_reviews

    aggregates = Review.where(status: "approved")
      .group(:recruiter_id)
      .select(:recruiter_id, "COUNT(*) AS reviews_count", "AVG(overall_score) AS avg_overall")

    @recruiters = Recruiter
      .joins("INNER JOIN (#{aggregates.to_sql}) agg ON agg.recruiter_id = recruiters.id")
      .where("agg.reviews_count >= ?", threshold)
      .select("recruiters.*, agg.reviews_count, agg.avg_overall")
      .order("agg.avg_overall DESC NULLS LAST")
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
  end
end

