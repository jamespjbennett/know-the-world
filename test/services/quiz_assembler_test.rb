require "test_helper"

# QuizAssembler specification
#
# Public interface:
#   QuizAssembler.call(quiz:, subscription:, new_questions:, quiz_size:)
#
# Creates QuizQuestion rows on the quiz: new material first, then review (~30%).
# Returns the quiz with ordered quiz_questions loaded.
#
class QuizAssemblerTest < ActiveSupport::TestCase
  setup do
    @builder = QuizAssemblerScenarioBuilder.new
  end

  test "assembles quiz with approximately thirty percent review questions" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: Array.new(10) { { answered_correctly: true } }
    )

    quiz = @builder.pending_quiz(subscription)
    new_questions = @builder.new_questions_for(subscription, digest: quiz.digest, count: 10)

    result = QuizAssembler.call(
      quiz: quiz,
      subscription: subscription,
      new_questions: new_questions,
      quiz_size: 10
    )

    assert_equal 10, result.quiz_questions.count
    assert_equal 3, result.quiz_questions.review.count
    assert_equal 7, result.quiz_questions.new_material.count
  end

  test "uses only new questions when no review history exists" do
    subscription = @builder.subscription
    quiz = @builder.pending_quiz(subscription)
    new_questions = @builder.new_questions_for(subscription, digest: quiz.digest, count: 5)

    result = QuizAssembler.call(
      quiz: quiz,
      subscription: subscription,
      new_questions: new_questions,
      quiz_size: 5
    )

    assert_equal 5, result.quiz_questions.count
    assert_equal 0, result.quiz_questions.review.count
    assert_equal 5, result.quiz_questions.new_material.count
  end

  test "assigns sequential positions starting at one" do
    subscription = @builder.subscription
    quiz = @builder.pending_quiz(subscription)
    new_questions = @builder.new_questions_for(subscription, digest: quiz.digest, count: 3)

    result = QuizAssembler.call(
      quiz: quiz,
      subscription: subscription,
      new_questions: new_questions,
      quiz_size: 3
    )

    assert_equal [ 1, 2, 3 ], result.quiz_questions.pluck(:position)
  end

  test "places new material before review questions" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: Array.new(5) { { answered_correctly: true } }
    )

    quiz = @builder.pending_quiz(subscription)
    new_questions = @builder.new_questions_for(subscription, digest: quiz.digest, count: 5)

    result = QuizAssembler.call(
      quiz: quiz,
      subscription: subscription,
      new_questions: new_questions,
      quiz_size: 5
    )

    new_count = result.quiz_questions.new_material.count
    review_positions = result.quiz_questions.review.pluck(:position)
    new_positions = result.quiz_questions.new_material.pluck(:position)

    assert review_positions.all? { |position| position > new_count }
    assert new_positions.all? { |position| position <= new_count }
  end

  test "does not include new questions in the review pool" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: [ { answered_correctly: true } ]
    )

    quiz = @builder.pending_quiz(subscription)
    new_questions = @builder.new_questions_for(subscription, digest: quiz.digest, count: 2)

    result = QuizAssembler.call(
      quiz: quiz,
      subscription: subscription,
      new_questions: new_questions,
      quiz_size: 2
    )

    review_ids = result.quiz_questions.review.pluck(:question_id)
    new_ids = new_questions.map(&:id)

    assert_empty review_ids & new_ids
  end

  test "uses fewer than quiz size when not enough questions are available" do
    subscription = @builder.subscription
    quiz = @builder.pending_quiz(subscription)
    new_questions = @builder.new_questions_for(subscription, digest: quiz.digest, count: 3)

    result = QuizAssembler.call(
      quiz: quiz,
      subscription: subscription,
      new_questions: new_questions,
      quiz_size: 10
    )

    assert_equal 3, result.quiz_questions.count
  end

  test "uses available review questions when fewer than thirty percent exist" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: [ { answered_correctly: true } ]
    )

    quiz = @builder.pending_quiz(subscription)
    new_questions = @builder.new_questions_for(subscription, digest: quiz.digest, count: 10)

    result = QuizAssembler.call(
      quiz: quiz,
      subscription: subscription,
      new_questions: new_questions,
      quiz_size: 10
    )

    assert_equal 10, result.quiz_questions.count
    assert_equal 1, result.quiz_questions.review.count
    assert_equal 9, result.quiz_questions.new_material.count
  end
end
