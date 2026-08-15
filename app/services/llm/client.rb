module Llm
  class Client
    class Error < StandardError; end

    def synthesize(subscription:, search_results:)
      raise Error, "LLM client not configured — inject a real adapter"
    end

    def generate_questions(subscription:, digest_content:, count:)
      raise Error, "LLM client not configured — inject a real adapter"
    end
  end
end
