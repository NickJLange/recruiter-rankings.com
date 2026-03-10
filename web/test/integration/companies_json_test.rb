require "test_helper"

class CompaniesJsonTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Test Company", region: "Remote")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company, public_slug: "test-recruiter-json")
    @user = User.create!(role: "candidate", email_hmac: "companies-json-test-#{SecureRandom.hex}")

    # Create enough approved experiences to pass the threshold (PUBLIC_MIN_REVIEWS=1 in test)
    6.times do
      interaction = Interaction.create!(recruiter: @recruiter, target: @user, status: "approved")
      Experience.create!(interaction: interaction, rating: 5, status: "approved")
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
