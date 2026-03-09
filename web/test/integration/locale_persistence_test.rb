require "test_helper"

class LocalePersistenceTest < ActionDispatch::IntegrationTest
  test "locale persists via cookie between requests" do
    get "/person", params: { locale: :ja }
    assert_response :success
    assert_includes @response.body, "上位のリクルーター", "should render Japanese after switching"

    # Next request without locale param should still be Japanese
    get "/person"
    assert_response :success
    assert_includes @response.body, "上位のリクルーター", "should persist Japanese via cookie"
  end
end

