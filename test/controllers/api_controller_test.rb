require "test_helper"

class ApiControllerTest < ActionDispatch::IntegrationTest
  test "should get fetch_data" do
    get api_fetch_data_url
    assert_response :success
  end
end
