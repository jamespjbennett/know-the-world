require "test_helper"

# RecordQuizCompletion specification
#
# Public interface:
#   result = RecordQuizCompletion.call(quiz:, user:)
#
# Expected result object (RecordQuizCompletion::Result):
#   result.quiz              - completed Quiz
#   result.subscription      - updated TopicSubscription
#   result.fitness           - FitnessScorer::Result
#
# Preconditions:
#   - Quiz is in_progress
#   - Every question on the quiz has a QuestionAttempt from the user
#
# Behaviour:
#   1. Calculate quiz score (% correct, integer 0-100)
#   2. Mark quiz completed with score and completed_at
#   3. Increment subscription streak_count
#   4. Recalculate fitness via FitnessScorer and persist to subscription
#   5. Create or update today's FitnessSnapshot
#   6. Touch subscription last_activity_at
#
class RecordQuizCompletionTest < ActiveSupport::TestCase
  setup do
    @builder = RecordQuizCompletionScenarioBuilder.new
  end

  test "marks quiz as completed with score from attempts" do
    subscription = @builder.subscription
    quiz = @builder.in_progress_quiz(
      subscription,
      questions: [
        { answered_correctly: true },
        { answered_correctly: true },
        { answered_correctly: false },
        { answered_correctly: false }
      ]
    )

    result = RecordQuizCompletion.call(quiz: quiz, user: @builder.user)

    assert result.quiz.completed?
    assert_equal 50, result.quiz.score
    assert_not_nil result.quiz.completed_at
  end

  test "updates subscription fitness score via FitnessScorer" do
    subscription = @builder.subscription(streak_count: 0)
    quiz = @builder.in_progress_quiz(
      subscription,
      questions: [
        { answered_correctly: true },
        { answered_correctly: true }
      ]
    )

    result = RecordQuizCompletion.call(quiz: quiz, user: @builder.user)

    # 100% accuracy (50) + 1-day streak (14.29 consistency) + 0 retention
    assert_in_delta 54.29, result.subscription.fitness_score, 0.01
    assert_in_delta result.fitness.score, result.subscription.fitness_score, 0.01
  end

  test "creates fitness snapshot for today" do
    subscription = @builder.subscription(streak_count: 1)
    quiz = @builder.in_progress_quiz(
      subscription,
      questions: [ { answered_correctly: true } ]
    )

    assert_difference -> { subscription.fitness_snapshots.count }, 1 do
      RecordQuizCompletion.call(quiz: quiz, user: @builder.user)
    end

    snapshot = subscription.fitness_snapshots.find_by!(recorded_on: Date.current)
    assert_in_delta subscription.reload.fitness_score, snapshot.score, 0.01
  end

  test "updates existing fitness snapshot when completing another quiz same day" do
    subscription = @builder.subscription(streak_count: 2)
    subscription.fitness_snapshots.create!(score: 40, recorded_on: Date.current)

    first_quiz = @builder.in_progress_quiz(
      subscription,
      questions: [ { answered_correctly: true }, { answered_correctly: true } ],
      published_on: 1.day.ago
    )
    RecordQuizCompletion.call(quiz: first_quiz, user: @builder.user)

    second_quiz = @builder.in_progress_quiz(
      subscription,
      questions: [ { answered_correctly: false } ],
      published_on: Date.current
    )

    assert_no_difference -> { subscription.fitness_snapshots.count } do
      RecordQuizCompletion.call(quiz: second_quiz, user: @builder.user)
    end

    snapshot = subscription.fitness_snapshots.find_by!(recorded_on: Date.current)
    assert_in_delta subscription.reload.fitness_score, snapshot.score, 0.01
    refute_in_delta 40.0, snapshot.score, 0.01
  end

  test "increments streak count before recalculating fitness" do
    subscription = @builder.subscription(streak_count: 2)
    quiz = @builder.in_progress_quiz(
      subscription,
      questions: [ { answered_correctly: true } ]
    )

    result = RecordQuizCompletion.call(quiz: quiz, user: @builder.user)

    assert_equal 3, result.subscription.streak_count
    assert_in_delta 42.86, result.fitness.consistency, 0.01
  end

  test "updates subscription last activity at" do
    subscription = @builder.subscription
    subscription.update!(last_activity_at: 2.days.ago)
    quiz = @builder.in_progress_quiz(
      subscription,
      questions: [ { answered_correctly: true } ]
    )

    freeze_time do
      RecordQuizCompletion.call(quiz: quiz, user: @builder.user)

      assert_in_delta Time.current, subscription.reload.last_activity_at, 1.second
    end
  end

  test "raises when quiz is already completed" do
    subscription = @builder.subscription
    quiz = @builder.completed_quiz(subscription, score: 80, new_material: { correct: 1, total: 1 })

    assert_raises(RecordQuizCompletion::AlreadyCompleted) do
      RecordQuizCompletion.call(quiz: quiz, user: @builder.user)
    end
  end

  test "raises when quiz has unanswered questions" do
    subscription = @builder.subscription
    quiz = @builder.in_progress_quiz(
      subscription,
      questions: [ { answered_correctly: true } ]
    )
    @builder.add_unanswered_question(quiz)

    assert_raises(RecordQuizCompletion::IncompleteAttempts) do
      RecordQuizCompletion.call(quiz: quiz, user: @builder.user)
    end
  end

  test "includes review question attempts in fitness retention" do
    subscription = @builder.subscription(streak_count: 1)
    quiz = @builder.in_progress_quiz(
      subscription,
      questions: [
        { answered_correctly: true, review: false },
        { answered_correctly: true, review: true },
        { answered_correctly: false, review: true }
      ]
    )

    result = RecordQuizCompletion.call(quiz: quiz, user: @builder.user)

    assert_in_delta 50.0, result.fitness.retention, 0.01
  end
end
