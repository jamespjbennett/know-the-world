module Llm
  class AnthropicClient
    class SdkMessenger
      def initialize(api_key:, model:)
        @model = model
        @client = Anthropic::Client.new(api_key: api_key || ApiCredentials.anthropic_api_key)
      end

      def complete(system:, user:)
        message = @client.messages.create(
          model: @model,
          max_tokens: AnthropicClient::DEFAULT_MAX_TOKENS,
          system: system,
          messages: [ { role: "user", content: user } ]
        )
        text_from(message)
      end

      private

      def text_from(message)
        message.content
          .select { |block| block.type.to_s == "text" }
          .map(&:text)
          .join
      end
    end
  end
end
