class FakeSearchClient < Search::Client
  DEFAULT_RESULTS = [
    { title: "Source A", url: "https://example.com/a", snippet: "Snippet about topic A." },
    { title: "Source B", url: "https://example.com/b", snippet: "Snippet about topic B." }
  ].freeze

  attr_reader :queries, :last_query

  def initialize(results: DEFAULT_RESULTS)
    @results = results
    @queries = []
  end

  def search(query)
    @queries << query
    @last_query = query
    @results
  end
end

class FailingSearchClient < Search::Client
  def initialize(message: "search unavailable")
    @message = message
  end

  def search(_query)
    raise Search::Client::Error, @message
  end
end
