module Search
  class Client
    class Error < StandardError; end

    def search(query)
      raise Error, "Search client not configured — inject a real adapter"
    end
  end
end
