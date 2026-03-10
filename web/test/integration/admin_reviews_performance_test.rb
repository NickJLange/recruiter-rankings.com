require "test_helper"

class AdminReviewsPerformanceTest < ActionDispatch::IntegrationTest
  def setup
    sign_in_as_clerk(role: :moderator, providers: [:email, :linkedin, :github], two_factor: true)
    @company = Company.create!(name: "Test Co")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company, public_slug: "test-recruiter-perf")
    @user = User.create!(role: "candidate", email_hmac: "test-hmac-perf")

    # Create 10 pending reviews with responses
    10.times do |i|
      review = Review.create!(
        user: @user,
        recruiter: @recruiter,
        company: @company,
        overall_score: 5,
        text: "Review #{i}",
        status: "pending"
      )
      ReviewResponse.create!(review: review, user: @user, body: "Response #{i}")
    end
  end

  test "admin reviews index avoids N+1 query on review_responses" do
    # Warm up to load schemas, etc.
    get "/admin/reviews?limit=10&statuses=pending"

    # Expected queries:
    # 1. User (moderator actor check in controller - current_moderator_actor) -> 1 query
    # 2. Review load (includes recruiter, company) -> 1 query
    # 3. ReviewResponse load (if eager loaded) -> 1 query (or 0 if N+1 not fixed and we count N)
    #
    # With N+1:
    # 1 (User) + 1 (Reviews) + 10 (Responses) = 12 queries.
    # Optimized:
    # 1 (User) + 1 (Reviews) + 1 (Responses) = 3 queries.
    #
    # We set max to 5 to be safe.

    assert_queries(5) do
      get "/admin/reviews?limit=10&statuses=pending"
      assert_response :success
    end
  end

  private

  def assert_queries(expected_count, &block)
    counter = QueryCounter.new
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record", counter)
    yield
    ActiveSupport::Notifications.unsubscribe(subscriber)

    assert_operator counter.count, :<=, expected_count, "Expected #{expected_count} queries or fewer, but got #{counter.count}"
  end

  class QueryCounter
    attr_reader :count

    def initialize
      @count = 0
    end

    def call(name, start, finish, id, payload)
      return if payload[:name].in? %w[ SCHEMA CACHE ]
      @count += 1
    end
  end
end
