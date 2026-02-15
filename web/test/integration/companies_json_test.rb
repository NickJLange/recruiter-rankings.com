require "test_helper"

class CompaniesJsonTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Test Company", region: "Remote")
    # Create enough reviews to pass threshold (assume 5 to be safe)
    6.times do |i|
      Review.create!(
        company: @company,
        user: User.create!(role: "candidate", email_hmac: "user#{i}-#{SecureRandom.hex}"),
        overall_score: 5,
        text: "Review #{i}",
        status: "approved"
      )
    end
  end

  test "companies json returns data and check cache headers" do
    get "/companies.json", params: { per: 5 }
    assert_response :success

    # Check that data is returned
    json = JSON.parse(response.body)
    assert_not_empty json
    assert_equal "Test Company", json.first["name"]

    # Verify cache control headers
    cache_control = response.headers["Cache-Control"]
    assert_match(/max-age=1800/, cache_control)
    assert_match(/public/, cache_control)
  end
end
