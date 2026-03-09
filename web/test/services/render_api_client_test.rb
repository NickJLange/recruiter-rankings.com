require "test_helper"
require "minitest/mock"

class RenderApiClientTest < ActiveSupport::TestCase
  setup do
    ENV['RENDER_API_KEY'] = 'test_key'
    @client = RenderApiClient.new
  end

  test "databases returns parsed json on success" do
    stub_response_data = [
      { "id" => "pg-123", "name" => "main-db", "connectionInfo" => { "externalConnectionString" => "postgres://..." } }
    ]

    response = Net::HTTPOK.new('1.1', '200', 'OK')
    def response.body; @body; end
    response.instance_variable_set(:@body, stub_response_data.to_json)

    http_instance = Net::HTTP.new("api.render.com", 443)
    
    Net::HTTP.stub :new, http_instance do
      http_instance.stub :request, response do
        assert_equal stub_response_data, @client.databases
      end
    end
  end

  test "find_database_by_name returns the correct database" do
    stub_response_data = [
      { "id" => "pg-123", "name" => "main-db" },
      { "id" => "pg-456", "name" => "other-db" }
    ]

    @client.stub :databases, stub_response_data do
      db = @client.find_database_by_name("main-db")
      assert_equal "pg-123", db["id"]
    end
  end

  test "returns nil on error" do
    response = Net::HTTPBadRequest.new('1.1', '400', 'Bad Request')

    http_instance = Net::HTTP.new("api.render.com", 443)

    Net::HTTP.stub :new, http_instance do
      http_instance.stub :request, response do
        assert_nil @client.databases
      end
    end
  end
end