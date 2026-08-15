class DigestGenerator
  class RequestBuilder
    def self.build(**options)
      Request.new(**with_defaults(options))
    end

    def self.with_defaults(options)
      default_clients
        .merge(default_schedule)
        .merge(options)
    end

    def self.default_schedule
      { published_on: Date.current, quiz_size: DEFAULT_QUIZ_SIZE }
    end

    def self.default_clients
      { search_client: Search::Client.new, llm_client: Llm::Client.new }
    end
  end
end
