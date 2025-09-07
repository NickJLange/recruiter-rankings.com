module RecruitersHelper
  def reveals_daily_limit
    (ENV['REVEALS_PER_DAY'].presence || 3).to_i
  end

  def reveals_today_count
    counts = session[:reveal_counts] ||= {}
    counts[Date.current.to_s].to_i
  end

  def increment_reveals_today!
    counts = session[:reveal_counts] ||= {}
    today = Date.current.to_s
    counts[today] = counts[today].to_i + 1
    session[:reveal_counts] = counts
  end

  def add_revealed_recruiter!(id)
    ids = session[:revealed_recruiter_ids] ||= []
    ids << id
    ids.uniq!
    session[:revealed_recruiter_ids] = ids
  end

  def revealed_recruiter_ids
    session[:revealed_recruiter_ids] ||= []
  end

  def allowed_to_show_real_name?(recruiter, reviews_count: nil, avg_overall: nil)
    return true if recruiter.verified_at.present? && recruiter.consented?
    return true if revealed_recruiter_ids.include?(recruiter.id)

    if reviews_count.nil? || avg_overall.nil?
      stats = recruiter.reviews.where(status: 'approved').pluck(Arel.sql('COUNT(*), AVG(overall_score)')).first
      if stats
        reviews_count = stats[0].to_i
        avg_overall = stats[1]&.to_f
      end
    end

    reviews_count.to_i >= 5 && avg_overall && avg_overall.to_f >= 4.0
  end

  def display_name_for(recruiter, reviews_count: nil, avg_overall: nil)
    allowed_to_show_real_name?(recruiter, reviews_count: reviews_count, avg_overall: avg_overall) ? recruiter.name : recruiter.pseudonym
  end
end
