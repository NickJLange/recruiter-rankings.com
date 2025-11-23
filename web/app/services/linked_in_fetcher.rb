require 'net/http'
require 'uri'

class LinkedInFetcher
  def fetch(url)
    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = (ENV['LINKEDIN_FETCH_TIMEOUT'] || '5').to_i
    http.open_timeout = (ENV['LINKEDIN_FETCH_TIMEOUT'] || '5').to_i

    req = Net::HTTP::Get.new(uri.request_uri)
    req['User-Agent'] = ENV['LINKEDIN_FETCH_UA'].presence || 'RecruiterRankingsBot/0.1'

    res = http.request(req)
    return res.body if res.is_a?(Net::HTTPSuccess)

    nil
  rescue => _e
    nil
  end
end
