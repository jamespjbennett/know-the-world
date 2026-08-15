require "test_helper"

class SearchTavilyClientTest < ActiveSupport::TestCase
  test "search maps tavily results to title url snippet hashes" do
    http = FakeHttp.new(
      status: 200,
      body: {
        results: [
          { title: "Wire", url: "https://example.com/wire", content: "Policy update." },
          { title: "Brief", url: "https://example.com/brief", content: "More news." }
        ]
      }.to_json
    )
    client = Search::TavilyClient.new(api_key: "tvly-test", http: http)

    results = client.search("Climate Tech beginner")

    assert_equal 2, results.size
    assert_equal(
      { title: "Wire", url: "https://example.com/wire", snippet: "Policy update." },
      results.first
    )
    assert_equal "https://api.tavily.com/search", http.last_url
    assert_equal "Bearer tvly-test", http.last_headers["Authorization"]
    assert_equal "Climate Tech beginner", JSON.parse(http.last_body).fetch("query")
  end

  test "raises Search::Client::Error on non-success HTTP status" do
    http = FakeHttp.new(status: 401, body: { detail: { error: "Unauthorized" } }.to_json)
    client = Search::TavilyClient.new(api_key: "bad", http: http)

    error = assert_raises(Search::Client::Error) do
      client.search("query")
    end

    assert_match(/401/, error.message)
  end

  test "raises Search::Client::Error when http transport fails" do
    http = FakeHttp.new(error: StandardError.new("timeout"))
    client = Search::TavilyClient.new(api_key: "tvly-test", http: http)

    error = assert_raises(Search::Client::Error) do
      client.search("query")
    end

    assert_match(/timeout/, error.message)
  end

  class FakeHttp
    attr_reader :last_url, :last_body, :last_headers

    def initialize(status: 200, body: "{}", error: nil)
      @status = status
      @body = body
      @error = error
    end

    def post(url, body:, headers:)
      raise @error if @error

      @last_url = url
      @last_body = body
      @last_headers = headers
      Response.new(status: @status, body: @body)
    end

    Response = Data.define(:status, :body)
  end
end
