module Llm
  class Client
    class Error < StandardError; end

    def synthesize(subscription:, search_results:)
      raise NotImplementedError
    end

    def generate_questions(subscription:, digest_content:, count:)
      raise NotImplementedError
    end
  end
end
