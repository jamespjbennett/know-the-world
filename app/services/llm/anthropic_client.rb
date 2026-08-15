module Llm
  class AnthropicClient < Client
    DEFAULT_MODEL = "claude-haiku-4-5"
    DEFAULT_MAX_TOKENS = 4096

    def initialize(api_key: nil, model: DEFAULT_MODEL, messenger: nil)
      @messenger = messenger || SdkMessenger.new(api_key: api_key, model: model)
    end

    def synthesize(subscription:, search_results:)
      parse_synthesis(
        complete(
          system: SynthesisPrompt.system,
          user: SynthesisPrompt.user(subscription, search_results)
        )
      )
    end

    def generate_questions(subscription:, digest_content:, count:)
      parse_questions(
        complete(
          system: QuestionsPrompt.system,
          user: QuestionsPrompt.user(subscription, digest_content, count)
        )
      )
    end

    private

    def complete(system:, user:)
      @messenger.complete(system: system, user: user)
    rescue => error
      fail Error, error.message
    end

    def parse_synthesis(text)
      payload = JsonParser.parse(text)
      {
        content: payload.fetch("content"),
        sources: payload.fetch("sources")
      }
    rescue KeyError, JsonParser::Error => error
      fail Error, error.message
    end

    def parse_questions(text)
      payload = JsonParser.parse(text)
      payload.fetch("questions").map { |question| normalize_question(question) }
    rescue KeyError, JsonParser::Error => error
      fail Error, error.message
    end

    def normalize_question(question)
      {
        prompt: question.fetch("prompt"),
        options: question.fetch("options"),
        correct_index: question.fetch("correct_index"),
        explanation: question.fetch("explanation")
      }
    end
  end
end
