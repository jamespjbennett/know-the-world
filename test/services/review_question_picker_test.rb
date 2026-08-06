require "test_helper"

# ReviewQuestionPicker specification
#
# Public interface:
#   ReviewQuestionPicker.call(subscription, count:, excluding: [])
#
# Returns an Array of Question records to include as review questions in a quiz.
#
# Rules:
#   - Pick from the subscription's question bank (past completed quizzes only)
#   - Return at most `count` questions
#   - Return fewer when not enough history exists
#   - Prioritize questions previously answered incorrectly
#   - Never return duplicates
#   - Skip any question ids listed in `excluding` (e.g. today's new questions)
#
class ReviewQuestionPickerTest < ActiveSupport::TestCase
  setup do
    @builder = ReviewQuestionScenarioBuilder.new
  end

  test "returns no questions when subscription has no question history" do
    subscription = @builder.subscription

    questions = ReviewQuestionPicker.call(subscription, count: 3)

    assert_empty questions
  end

  test "returns requested number of questions when enough history exists" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: true },
        { answered_correctly: true },
        { answered_correctly: false },
        { answered_correctly: true }
      ]
    )

    questions = ReviewQuestionPicker.call(subscription, count: 3)

    assert_equal 3, questions.size
  end

  test "returns fewer questions when history is smaller than requested count" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: true },
        { answered_correctly: false }
      ]
    )

    questions = ReviewQuestionPicker.call(subscription, count: 5)

    assert_equal 2, questions.size
  end

  test "prioritizes questions previously answered incorrectly" do
    subscription = @builder.subscription
    wrong, _correct = @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: false },
        { answered_correctly: true },
        { answered_correctly: true }
      ]
    )

    questions = ReviewQuestionPicker.call(subscription, count: 1)

    assert_equal [ wrong ], questions
  end

  test "includes multiple wrong answers before correct ones" do
    subscription = @builder.subscription
    first_wrong, second_wrong, _correct = @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: false },
        { answered_correctly: false },
        { answered_correctly: true }
      ]
    )

    questions = ReviewQuestionPicker.call(subscription, count: 2)

    assert_equal Set.new([ first_wrong.id, second_wrong.id ]), Set.new(questions.map(&:id))
  end

  test "returns wrong answers before correct answers in priority order" do
    subscription = @builder.subscription
    wrong, first_correct, second_correct = @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: false },
        { answered_correctly: true },
        { answered_correctly: true }
      ]
    )

    questions = ReviewQuestionPicker.call(subscription, count: 3)

    assert_equal wrong, questions.first
    assert_equal Set.new([ first_correct.id, second_correct.id ]), Set.new(questions.drop(1).map(&:id))
  end

  test "uses the latest attempt when ranking priority" do
    subscription = @builder.subscription
    previously_wrong, still_wrong = @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: false },
        { answered_correctly: false }
      ],
      completed_at: 3.days.ago
    )
    @builder.reuse_question_in_quiz(
      subscription,
      previously_wrong,
      answered_correctly: true,
      completed_at: 1.day.ago
    )

    questions = ReviewQuestionPicker.call(subscription, count: 1)

    assert_equal [ still_wrong ], questions
  end

  test "prefers a question whose latest attempt is wrong even if earlier attempt was correct" do
    subscription = @builder.subscription
    previously_correct, always_correct = @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: true },
        { answered_correctly: true }
      ],
      completed_at: 3.days.ago
    )
    @builder.reuse_question_in_quiz(
      subscription,
      previously_correct,
      answered_correctly: false,
      completed_at: 1.day.ago
    )

    questions = ReviewQuestionPicker.call(subscription, count: 1)

    assert_equal [ previously_correct ], questions
    refute_equal always_correct, questions.first
  end

  test "aggregates candidates across multiple completed quizzes" do
    subscription = @builder.subscription
    wrong, correct_from_first = @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: false },
        { answered_correctly: true }
      ],
      completed_at: 7.days.ago
    )
    correct_from_second = @builder.past_quiz_with_questions(
      subscription,
      questions: [ { answered_correctly: true } ],
      completed_at: 1.day.ago
    ).first

    questions = ReviewQuestionPicker.call(subscription, count: 3)

    assert_equal 3, questions.size
    assert_equal wrong, questions.first
    assert_equal Set.new([ correct_from_first.id, correct_from_second.id ]), Set.new(questions.drop(1).map(&:id))
  end

  test "returns a question only once when it appears in multiple completed quizzes" do
    subscription = @builder.subscription
    question = @builder.past_quiz_with_questions(
      subscription,
      questions: [ { answered_correctly: false } ],
      completed_at: 3.days.ago
    ).first
    @builder.reuse_question_in_quiz(
      subscription,
      question,
      answered_correctly: true,
      completed_at: 1.day.ago
    )

    questions = ReviewQuestionPicker.call(subscription, count: 2)

    assert_equal [ question ], questions
  end

  test "only picks questions from the given subscription" do
    subscription = @builder.subscription
    other_subscription = @builder.subscription

    mine = @builder.past_quiz_with_questions(
      subscription,
      questions: [ { answered_correctly: true } ]
    )
    @builder.past_quiz_with_questions(
      other_subscription,
      questions: [ { answered_correctly: true }, { answered_correctly: true } ]
    )

    questions = ReviewQuestionPicker.call(subscription, count: 2)

    assert_equal mine, questions
  end

  test "excludes questions listed in excluding" do
    subscription = @builder.subscription
    first, second, third = @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: false },
        { answered_correctly: false },
        { answered_correctly: false }
      ]
    )

    questions = ReviewQuestionPicker.call(
      subscription,
      count: 2,
      excluding: [ first.id, second.id ]
    )

    assert_equal [ third ], questions
  end

  test "never returns duplicate questions" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: [
        { answered_correctly: false },
        { answered_correctly: false },
        { answered_correctly: true },
        { answered_correctly: true }
      ]
    )

    questions = ReviewQuestionPicker.call(subscription, count: 4)

    assert_equal questions.size, questions.map(&:id).uniq.size
  end

  test "ignores questions from incomplete quizzes" do
    subscription = @builder.subscription
    available = @builder.past_quiz_with_questions(
      subscription,
      questions: [ { answered_correctly: true } ]
    )

    incomplete_digest = subscription.digests.create!(
      published_on: Date.current,
      status: :ready,
      content: "Digest content",
      sources: []
    )
    incomplete_quiz = incomplete_digest.create_quiz!(status: :in_progress)
    skipped = subscription.questions.create!(
      digest: incomplete_digest,
      prompt: "Incomplete question?",
      options: ReviewQuestionScenarioBuilder::DEFAULT_OPTIONS,
      correct_index: 0,
      explanation: "Because."
    )
    incomplete_quiz.quiz_questions.create!(question: skipped, position: 1, review: false)

    questions = ReviewQuestionPicker.call(subscription, count: 2)

    assert_equal available, questions
    refute_includes questions, skipped
  end

  test "returns no questions when count is zero" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: [ { answered_correctly: false } ]
    )

    questions = ReviewQuestionPicker.call(subscription, count: 0)

    assert_empty questions
  end

  test "returns no questions when every candidate is excluded" do
    subscription = @builder.subscription
    only = @builder.past_quiz_with_questions(
      subscription,
      questions: [ { answered_correctly: false } ]
    ).first

    questions = ReviewQuestionPicker.call(subscription, count: 3, excluding: [ only.id ])

    assert_empty questions
  end
end
