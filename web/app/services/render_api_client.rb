require 'net/http'
require 'uri'
require 'json'

class RenderApiClient
  BASE_URL = "https://api.render.com/v1"

  def initialize(api_key: ENV['RENDER_API_KEY'])
    @api_key = api_key
  end

  def databases
    get("/postgres")
  end

  def find_database_by_name(name)
    databases.find { |db| db['name'] == name }
  end

  private

  def get(path)
    uri = URI.parse("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Accept'] = 'application/json'

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      # Handle error or return nil
      nil
    end
  rescue => e
    Rails.logger.error "RenderApiClient Error: #{e.message}"
    nil
  end
end
