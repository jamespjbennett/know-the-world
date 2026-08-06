# Builds in-progress quizzes with attempts for RecordQuizCompletion tests.
#
class RecordQuizCompletionScenarioBuilder < FitnessScenarioBuilder
  def in_progress_quiz(subscription, questions:, published_on: Date.current)
    digest = subscription.digests.create!(
      published_on: published_on,
      status: :ready,
      content: "Digest content",
      sources: []
    )

    quiz = digest.create_quiz!(status: :in_progress)

    questions.each do |attributes|
      add_question_with_attempt(
        quiz: quiz,
        answered_correctly: attributes.fetch(:answered_correctly),
        review: attributes.fetch(:review, false)
      )
    end

    quiz
  end

  def add_unanswered_question(quiz)
    question = quiz.topic_subscription.questions.create!(
      digest: quiz.digest,
      prompt: "Unanswered question #{Question.count + 1}?",
      options: DEFAULT_OPTIONS,
      correct_index: 0,
      explanation: "Because."
    )

    quiz.quiz_questions.create!(
      question: question,
      position: quiz.quiz_questions.count + 1,
      review: false
    )

    question
  end

  def pending_quiz_with_attempts(subscription, questions:, published_on: Date.current)
    quiz = in_progress_quiz(subscription, questions: questions, published_on: published_on)
    quiz.update!(status: :pending)
    quiz
  end

  private

  def add_question_with_attempt(quiz:, answered_correctly:, review:)
    question = quiz.topic_subscription.questions.create!(
      digest: quiz.digest,
      prompt: "Question #{Question.count + 1}?",
      options: DEFAULT_OPTIONS,
      correct_index: 0,
      explanation: "Because."
    )

    quiz.quiz_questions.create!(
      question: question,
      position: quiz.quiz_questions.count + 1,
      review: review
    )

    quiz.question_attempts.create!(
      user: quiz.digest.topic_subscription.user,
      question: question,
      selected_index: answered_correctly ? 0 : 1
    )

    question
  end
end
