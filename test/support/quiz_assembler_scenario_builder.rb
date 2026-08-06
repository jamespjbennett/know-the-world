# Builds quizzes and new questions for QuizAssembler tests.
#
class QuizAssemblerScenarioBuilder
  def initialize
    @builder = ReviewQuestionScenarioBuilder.new
  end

  def subscription(**options)
    @builder.subscription(**options)
  end

  def past_quiz_with_questions(subscription, **options)
    @builder.past_quiz_with_questions(subscription, **options)
  end

  def pending_quiz(subscription, published_on: Date.current)
    digest = subscription.digests.create!(
      published_on: published_on,
      status: :ready,
      content: "Digest content",
      sources: []
    )

    digest.create_quiz!(status: :pending)
  end

  def new_questions_for(subscription, digest:, count:)
    count.times.map do
      subscription.questions.create!(
        digest: digest,
        prompt: "New question #{Question.count + 1}?",
        options: ReviewQuestionScenarioBuilder::DEFAULT_OPTIONS,
        correct_index: 0,
        explanation: "Because."
      )
    end
  end
end
