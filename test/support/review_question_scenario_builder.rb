# Builds question history for ReviewQuestionPicker tests.
#
# Usage:
#   builder = ReviewQuestionScenarioBuilder.new
#   subscription = builder.subscription
#   builder.past_quiz_with_questions(subscription, questions: [
#     { answered_correctly: false },
#     { answered_correctly: true }
#   ])
#
class ReviewQuestionScenarioBuilder
  DEFAULT_OPTIONS = %w[A B C D].freeze

  def initialize(email: nil)
    @user = User.create!(email_address: email || unique_email, password: "password")
  end

  attr_reader :user

  def subscription(**options)
    topic = Topic.create!(
      name: "Topic #{Topic.count + 1}",
      curated: true,
      description: "Test topic"
    )

    TopicSubscription.create!(
      user: @user,
      topic: topic,
      goal: options.fetch(:goal, "Understand the topic deeply"),
      cadence: options.fetch(:cadence, :daily),
      streak_count: options.fetch(:streak_count, 0)
    )
  end

  def past_quiz_with_questions(subscription, questions:, completed_at: 1.day.ago)
    digest = subscription.digests.create!(
      published_on: completed_at.to_date,
      status: :ready,
      content: "Digest content",
      sources: []
    )

    quiz = digest.create_quiz!(
      status: :completed,
      score: 0,
      completed_at: completed_at
    )

    questions.map do |attributes|
      create_question_with_attempt(
        subscription: subscription,
        quiz: quiz,
        digest: digest,
        answered_correctly: attributes.fetch(:answered_correctly),
        attempted_at: completed_at
      )
    end
  end

  # Reuses an existing question on a new completed quiz (review path + distinct join).
  def reuse_question_in_quiz(subscription, question, answered_correctly:, completed_at: Time.current)
    digest = subscription.digests.create!(
      published_on: completed_at.to_date,
      status: :ready,
      content: "Digest content",
      sources: []
    )

    quiz = digest.create_quiz!(
      status: :completed,
      score: 0,
      completed_at: completed_at
    )

    quiz.quiz_questions.create!(
      question: question,
      position: 1,
      review: true
    )

    quiz.question_attempts.create!(
      user: @user,
      question: question,
      selected_index: answered_correctly ? 0 : 1,
      created_at: completed_at
    )

    question
  end

  private

  def unique_email
    "review-picker-#{SecureRandom.hex(4)}@example.com"
  end

  def create_question_with_attempt(subscription:, quiz:, digest:, answered_correctly:, attempted_at:)
    question = subscription.questions.create!(
      digest: digest,
      prompt: "Question #{Question.count + 1}?",
      options: DEFAULT_OPTIONS,
      correct_index: 0,
      explanation: "Because."
    )

    quiz.quiz_questions.create!(
      question: question,
      position: quiz.quiz_questions.count + 1,
      review: false
    )

    quiz.question_attempts.create!(
      user: @user,
      question: question,
      selected_index: answered_correctly ? 0 : 1,
      created_at: attempted_at
    )

    question
  end
end
