class FakeLlmClient < Llm::Client
  attr_reader :synthesize_calls, :generate_questions_calls

  def initialize(content: "Generated digest content.", sources: nil, question_count: nil)
    @content = content
    @sources = sources || [{ title: "Source A", url: "https://example.com/a" }]
    @question_count = question_count
    @synthesize_calls = []
    @generate_questions_calls = []
  end

  def synthesize(subscription:, search_results:)
    @synthesize_calls << { subscription: subscription, search_results: search_results }
    { content: @content, sources: @sources }
  end

  def generate_questions(subscription:, digest_content:, count:)
    @generate_questions_calls << {
      subscription: subscription,
      digest_content: digest_content,
      count: count
    }

    requested = @question_count || count
    requested.times.map do |index|
      {
        prompt: "Generated question #{index + 1}?",
        options: ReviewQuestionScenarioBuilder::DEFAULT_OPTIONS,
        correct_index: 0,
        explanation: "Because the digest says so."
      }
    end
  end
end

class FailingLlmSynthesizeClient < Llm::Client
  def initialize(message: "synthesis failed")
    @message = message
  end

  def synthesize(**)
    raise Llm::Client::Error, @message
  end

  def generate_questions(**)
    raise NotImplementedError
  end
end

class FailingLlmQuestionsClient < Llm::Client
  def initialize(message: "question generation failed")
    @message = message
  end

  def synthesize(**)
    {
      content: "Partial digest content.",
      sources: [{ title: "Source A", url: "https://example.com/a" }]
    }
  end

  def generate_questions(**)
    raise Llm::Client::Error, @message
  end
end
