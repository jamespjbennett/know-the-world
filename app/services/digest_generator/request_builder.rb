class DigestGenerator
  class RequestBuilder
    def self.build(**options)
      Request.new(
        subscription: options.fetch(:subscription),
        published_on: options.fetch(:published_on, Date.current),
        quiz_size: options.fetch(:quiz_size, DEFAULT_QUIZ_SIZE),
        search_client: options.fetch(:search_client) { Search::TavilyClient.new },
        llm_client: options.fetch(:llm_client) { Llm::AnthropicClient.new }
      )
    end
  end
end
