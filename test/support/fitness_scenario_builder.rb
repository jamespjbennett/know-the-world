# Builds realistic subscription + quiz data for fitness scoring tests.
#
# Usage:
#   builder = FitnessScenarioBuilder.new
#   subscription = builder.subscription(cadence: :daily, streak_count: 3)
#   builder.completed_quiz(subscription, score: 80, review: { correct: 2, total: 3 })
#
class FitnessScenarioBuilder
  DEFAULT_OPTIONS = [ "A", "B", "C", "D" ].freeze

  def initialize(email: "fitness-test@example.com")
    @user = User.create!(email_address: email, password: "password")
  end

  attr_reader :user

  def subscription(cadence: :daily, streak_count: 0, goal: "Understand the topic deeply")
    topic = Topic.create!(
      name: "Topic #{Topic.count + 1}",
      curated: true,
      description: "Test topic"
    )

    TopicSubscription.create!(
      user: @user,
      topic: topic,
      goal: goal,
      cadence: cadence,
      streak_count: streak_count
    )
  end

  # Creates a completed quiz with optional review/new-material attempts.
  #
  # score:           integer 0-100 stored on the quiz (drives accuracy component)
  # review:          { correct:, total: } review questions attempted
  # new_material:    { correct:, total: } new digest questions attempted
  # completed_at:    timestamp for ordering when testing rolling windows
  #
  def completed_quiz(subscription, score:, review: { correct: 0, total: 0 }, new_material: { correct: 0, total: 0 }, completed_at: Time.current)
    digest = subscription.digests.create!(
      published_on: completed_at.to_date,
      status: :ready,
      content: "Digest content",
      sources: []
    )

    quiz = digest.create_quiz!(
      status: :completed,
      score: score,
      completed_at: completed_at
    )

    add_attempts(quiz, review: review, review_flag: true)
    add_attempts(quiz, review: new_material, review_flag: false)

    quiz
  end

  def incomplete_quiz(subscription, status: :in_progress, completed_at: Time.current)
    digest = subscription.digests.create!(
      published_on: completed_at.to_date,
      status: :ready,
      content: "Digest content",
      sources: []
    )

    digest.create_quiz!(status: status)
  end

  private

  def add_attempts(quiz, review:, review_flag:)
    total = review[:total]
    correct = review[:correct]

    total.times do |index|
      question = quiz.topic_subscription.questions.create!(
        digest: quiz.digest,
        prompt: "Question #{Question.count + 1}?",
        options: DEFAULT_OPTIONS,
        correct_index: 0,
        explanation: "Because."
      )

      quiz.quiz_questions.create!(question: question, position: quiz.quiz_questions.count + 1, review: review_flag)

      selected_index = index < correct ? 0 : 1
      quiz.question_attempts.create!(user: @user, question: question, selected_index: selected_index)
    end
  end
end
