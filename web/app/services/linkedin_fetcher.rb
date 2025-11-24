require 'net/http'
require 'uri'

class LinkedinFetcher
  ALLOWED_HOSTS = ["linkedin.com", "www.linkedin.com"].freeze
  DEFAULT_TIMEOUT = 5

  def initialize(timeout: nil, user_agent: nil)
    env_timeout = Integer(ENV['LINKEDIN_FETCH_TIMEOUT'], exception: false)
    @timeout = if timeout
                  timeout.positive? ? timeout : DEFAULT_TIMEOUT
                elsif env_timeout && env_timeout.positive?
                  env_timeout
                else
                  DEFAULT_TIMEOUT
                end
    @user_agent = user_agent || ENV['LINKEDIN_FETCH_UA'].presence || 'RecruiterRankingsBot/0.1'
  end

  def fetch(url)
    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)
    return nil unless ALLOWED_HOSTS.any? { |host| uri.host == host || uri.host&.end_with?(".#{host}") }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = @timeout
    http.open_timeout = @timeout

    req = Net::HTTP::Get.new(uri.request_uri)
    req['User-Agent'] = @user_agent

    res = http.request(req)
    return res.body if res.is_a?(Net::HTTPSuccess)

    nil
  rescue => e
    Rails.logger.warn("LinkedinFetcher failed for #{uri.host}: #{e.class}")
    nil
  end
end
