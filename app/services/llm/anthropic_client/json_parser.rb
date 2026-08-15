module Llm
  class AnthropicClient
    class JsonParser
      class Error < StandardError; end

      FENCE = /\A```(?:json)?\s*/i
      CLOSING_FENCE = /\s*```\z/

      def self.parse(text)
        new(text).parse
      end

      def initialize(text)
        @text = text.to_s.strip
      end

      def parse
        JSON.parse(stripped)
      rescue JSON::ParserError => error
        fail Error, "Invalid LLM JSON: #{error.message}"
      end

      private

      def stripped
        @text.sub(FENCE, "").sub(CLOSING_FENCE, "").strip
      end
    end
  end
end
