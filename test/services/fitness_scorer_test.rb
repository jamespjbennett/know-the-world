require "test_helper"

# FitnessScorer specification (implementation not yet written)
#
# Public interface:
#   result = FitnessScorer.call(topic_subscription)
#
# Expected result object (FitnessScorer::Result):
#   result.score        - Float, 0-100, weighted composite
#   result.accuracy     - Float, 0-100
#   result.consistency  - Float, 0-100
#   result.retention    - Float, 0-100
#
# Formula (from docs/PRD.md):
#   score = (accuracy * 0.5) + (consistency * 0.3) + (retention * 0.2)
#
# Components:
#   accuracy    - rolling average of the last 10 completed quiz scores
#   consistency - streak_count relative to cadence target (daily: 7 days, weekly: 4 weeks), capped at 100
#   retention   - percentage of correct attempts on review (spaced-repetition) questions
#
class FitnessScorerTest < ActiveSupport::TestCase
  setup do
    @builder = FitnessScenarioBuilder.new
  end

  test "returns zero score when subscription has no completed quizzes" do
    subscription = @builder.subscription

    result = FitnessScorer.call(subscription)

    assert_in_delta 0.0, result.score, 0.01
    assert_in_delta 0.0, result.accuracy, 0.01
    assert_in_delta 0.0, result.consistency, 0.01
    assert_in_delta 0.0, result.retention, 0.01
  end

  test "computes accuracy from a single completed quiz score" do
    subscription = @builder.subscription
    @builder.completed_quiz(subscription, score: 80)

    result = FitnessScorer.call(subscription)

    assert_in_delta 80.0, result.accuracy, 0.01
  end

  test "computes accuracy as rolling average of last ten completed quizzes" do
    subscription = @builder.subscription

    scores = [ 100, 80 ] + [ 60 ] * 8
    scores.each_with_index do |score, index|
      @builder.completed_quiz(subscription, score: score, completed_at: index.days.ago)
    end

    result = FitnessScorer.call(subscription)

    # (8 * 60 + 80 + 100) / 10 = 700 / 10 = 70
    assert_in_delta 70.0, result.accuracy, 0.01
  end

  test "ignores completed quizzes beyond the last ten when computing accuracy" do
    subscription = @builder.subscription

    5.times { |day| @builder.completed_quiz(subscription, score: 0, completed_at: (20 + day).days.ago) }
    10.times { |day| @builder.completed_quiz(subscription, score: 100, completed_at: day.days.ago) }

    result = FitnessScorer.call(subscription)

    assert_in_delta 100.0, result.accuracy, 0.01
  end

  test "ignores incomplete quizzes when computing accuracy" do
    subscription = @builder.subscription

    @builder.incomplete_quiz(subscription, completed_at: 1.day.ago)
    @builder.completed_quiz(subscription, score: 90)

    result = FitnessScorer.call(subscription)

    assert_in_delta 90.0, result.accuracy, 0.01
  end

  test "computes daily consistency from streak relative to seven day target" do
    subscription = @builder.subscription(cadence: :daily, streak_count: 3)
    @builder.completed_quiz(subscription, score: 0)

    result = FitnessScorer.call(subscription)

    # 3 / 7 * 100 = 42.857...
    assert_in_delta 42.86, result.consistency, 0.01
  end

  test "caps daily consistency at one hundred when streak meets seven day target" do
    subscription = @builder.subscription(cadence: :daily, streak_count: 10)
    @builder.completed_quiz(subscription, score: 0)

    result = FitnessScorer.call(subscription)

    assert_in_delta 100.0, result.consistency, 0.01
  end

  test "computes weekly consistency from streak relative to four week target" do
    subscription = @builder.subscription(cadence: :weekly, streak_count: 2)
    @builder.completed_quiz(subscription, score: 0)

    result = FitnessScorer.call(subscription)

    # 2 / 4 * 100 = 50
    assert_in_delta 50.0, result.consistency, 0.01
  end

  test "computes retention from accuracy on review questions only" do
    subscription = @builder.subscription
    @builder.completed_quiz(
      subscription,
      score: 50,
      review: { correct: 2, total: 3 },
      new_material: { correct: 0, total: 3 }
    )

    result = FitnessScorer.call(subscription)

    # 2/3 correct on review questions = 66.667...
    assert_in_delta 66.67, result.retention, 0.01
  end

  test "returns zero retention when no review questions have been attempted" do
    subscription = @builder.subscription
    @builder.completed_quiz(
      subscription,
      score: 100,
      new_material: { correct: 5, total: 5 }
    )

    result = FitnessScorer.call(subscription)

    assert_in_delta 0.0, result.retention, 0.01
  end

  test "combines components with fifty thirty twenty weights" do
    subscription = @builder.subscription(cadence: :daily, streak_count: 3)
    @builder.completed_quiz(
      subscription,
      score: 70,
      review: { correct: 2, total: 2 }
    )

    result = FitnessScorer.call(subscription)

    accuracy = 70.0
    consistency = (3.0 / 7.0) * 100
    retention = 100.0
    expected = (accuracy * 0.5) + (consistency * 0.3) + (retention * 0.2)

    assert_in_delta expected, result.score, 0.01
    assert_in_delta accuracy, result.accuracy, 0.01
    assert_in_delta consistency, result.consistency, 0.01
    assert_in_delta retention, result.retention, 0.01
  end

  test "clamps final score between zero and one hundred" do
    subscription = @builder.subscription(cadence: :daily, streak_count: 10)
    @builder.completed_quiz(
      subscription,
      score: 100,
      review: { correct: 5, total: 5 }
    )

    result = FitnessScorer.call(subscription)

    assert result.score.between?(0, 100)
    assert result.accuracy.between?(0, 100)
    assert result.consistency.between?(0, 100)
    assert result.retention.between?(0, 100)
  end
end
