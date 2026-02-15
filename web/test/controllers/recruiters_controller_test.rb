require "test_helper"

class RecruitersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @recruiter = recruiters(:one)
    # Ensure recruiter has public slug
    @recruiter.update!(public_slug: "DEADBEEF")
    
    @user_paid = users(:candidate_paid)
    @user_free = users(:candidate_free)
    @admin = users(:admin)
    @owner = users(:owner)
    Interaction.create!(recruiter: @recruiter, target: @owner, occurred_at: 1.month.ago, status: "approved")
  end

  test "should get index" do
    get recruiters_url
    assert_response :success
    # Regression check: Anonymous users should see masked names
    assert_select "td", text: /Recruiter/
    assert_no_match @recruiter.name, response.body
  end

  test "anonymous user sees restricted view and masked name" do
    get recruiter_url(@recruiter)
    assert_response :success
    # Check for masked name (Recruiter + Hex chunk)
    assert_select "h1", text: /Recruiter [0-9A-F]+/
    assert_no_match @recruiter.name, response.body
    
    assert_select "h2", text: "Quarterly Performance (Median)"
    
    JSON.parse(response.body.match(/<script.*?>(.*?)<\/script>/m) ? "{}" : get_json_response)
    # Since we can't easily parse JSON from HTML response in integration test unless we request json 
    # Let's request JSON explicitely
    get recruiter_url(@recruiter, format: :json)
    json = JSON.parse(response.body)
    assert json.key?("quarterly")
    assert_not json.key?("reviews")
  end

  test "paid user sees full view and real name" do
    sign_in_as(@user_paid)
    
    get recruiter_url(@recruiter)
    assert_response :success
    assert_select "h1", text: @recruiter.name
    assert_select "h2", text: "Recent reviews"
    
    get recruiter_url(@recruiter, format: :json)
    json = JSON.parse(response.body)
    assert json.key?("reviews")
    assert json.key?("dimensional_averages")
    assert_not json.key?("quarterly")
  end

  test "owner sees full view and real name" do
    sign_in_as(@owner)
    
    get recruiter_url(@recruiter)
    assert_response :success
    assert_select "h1", text: @recruiter.name
    assert_select "h2", text: "Recent reviews"
  end

  private

  def get_json_response
    response.body
  end
end
