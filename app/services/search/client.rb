module Search
  class Client
    class Error < StandardError; end

    def search(query)
      raise NotImplementedError
    end
  end
end
