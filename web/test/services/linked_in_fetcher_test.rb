require "test_helper"
require "minitest/mock"

class LinkedInFetcherTest < ActiveSupport::TestCase
  test "fetches arbitrary url (reproduction of SSRF) - blocked" do
    fetcher = LinkedInFetcher.new
    url = "http://example.com/sensitive-data"

    # We expect NO request to be made because of the host validation

    result = fetcher.fetch(url)
    assert_nil result
  end

  test "fetches linkedin url - allowed" do
    fetcher = LinkedInFetcher.new
    url = "https://www.linkedin.com/in/someuser"

    # The implementation uses block form of http.request, so we stub at a higher level
    # by stubbing Net::HTTP.new to return a mock that handles the block form
    response_body = "linkedin profile"

    stub_http = Object.new
    def stub_http.use_ssl=(_v); end
    def stub_http.read_timeout=(_v); end
    def stub_http.open_timeout=(_v); end
    def stub_http.started?; false; end

    # The block form: http.request(req) { |response| ... }
    # We need to yield a response object to the block
    stub_response = Object.new
    stub_response.define_singleton_method(:is_a?) { |klass| klass == Net::HTTPSuccess || klass == Net::HTTPPartialContent }
    stub_response.define_singleton_method(:read_body) { |&blk| blk.call("linkedin profile") }

    stub_http.define_singleton_method(:request) { |req, &blk| blk.call(stub_response) if blk }

    Net::HTTP.stub :new, stub_http do
      result = fetcher.fetch(url)
      assert_equal response_body, result
    end
  end
end
