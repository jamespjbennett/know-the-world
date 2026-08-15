module Search
  class TavilyClient < Client
    ENDPOINT = "https://api.tavily.com/search"
    DEFAULT_MAX_RESULTS = 5

    def initialize(api_key: nil, http: nil, max_results: DEFAULT_MAX_RESULTS)
      @api_key = api_key || ApiCredentials.tavily_api_key
      @http = http || HttpPoster.new
      @max_results = max_results
    end

    def search(query)
      response = post(query)
      ensure_success!(response)
      map_results(JSON.parse(response.body))
    rescue Error
      raise
    rescue => error
      fail Error, error.message
    end

    private

    def post(query)
      @http.post(
        ENDPOINT,
        body: request_body(query),
        headers: request_headers
      )
    end

    def request_body(query)
      {
        query: query,
        max_results: @max_results,
        search_depth: "basic"
      }.to_json
    end

    def request_headers
      {
        "Authorization" => "Bearer #{@api_key}",
        "Content-Type" => "application/json"
      }
    end

    def ensure_success!(response)
      return if response.status.to_i.between?(200, 299)

      fail Error, "Tavily search failed with HTTP #{response.status}"
    end

    def map_results(payload)
      Array(payload["results"]).map { |result| map_result(result) }
    end

    def map_result(result)
      {
        title: result["title"],
        url: result["url"],
        snippet: result["content"]
      }
    end
  end
end
