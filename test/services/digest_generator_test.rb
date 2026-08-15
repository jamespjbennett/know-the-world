require "test_helper"

# DigestGenerator specification
#
# Public interface:
#   result = DigestGenerator.call(
#     subscription:,
#     published_on: Date.current,
#     quiz_size: DigestGenerator::DEFAULT_QUIZ_SIZE,
#     search_client: Search::Client.new,
#     llm_client: Llm::Client.new
#   )
#
# Expected result object (DigestGenerator::Result):
#   result.digest         - ready TopicDigest with content and sources
#   result.quiz           - pending Quiz assembled via QuizAssembler
#   result.new_questions  - Array of new Question records from the LLM
#
# Orchestration:
#   1. Build search query from subscription (Search::QueryBuilder)
#   2. Web search via search_client
#   3. LLM digest synthesis via llm_client
#   4. LLM new MCQ generation via llm_client
#   5. Persist TopicDigest, Question rows, pending Quiz
#   6. QuizAssembler mixes new + review questions
#   7. Mark digest ready and touch subscription last_activity_at
#
# Errors:
#   DigestGenerator::AlreadyGenerated - digest already exists for published_on
#   Search::Client::Error / Llm::Client::Error - digest marked failed, error re-raised
#
class DigestGeneratorTest < ActiveSupport::TestCase
  setup do
    @builder = DigestGeneratorScenarioBuilder.new
  end

  test "creates ready digest with llm content and sources" do
    subscription = @builder.subscription
    llm = @builder.fake_llm_client(
      content: "Today's briefing on the topic.",
      sources: [{ title: "Reuters", url: "https://example.com/reuters" }]
    )

    result = @builder.generate(subscription, llm_client: llm)

    assert result.digest.ready?
    assert_equal "Today's briefing on the topic.", result.digest.content
    assert_equal [{ "title" => "Reuters", "url" => "https://example.com/reuters" }], result.digest.sources
    assert_equal Date.current, result.digest.published_on
  end

  test "searches with query built from subscription" do
    subscription = @builder.subscription(
      goal: "Track policy changes",
      knowledge_level: :advanced
    )
    search = @builder.fake_search_client

    @builder.generate(subscription, search_client: search)

    assert_equal 1, search.queries.size
    assert_includes search.last_query, subscription.topic.name
    assert_includes search.last_query, "Track policy changes"
    assert_includes search.last_query, "advanced"
  end

  test "passes search results to llm synthesis" do
    subscription = @builder.subscription
    search_results = [{ title: "Wire", url: "https://example.com/wire", snippet: "News." }]
    search = @builder.fake_search_client(results: search_results)
    llm = @builder.fake_llm_client

    @builder.generate(subscription, search_client: search, llm_client: llm)

    assert_equal 1, llm.synthesize_calls.size
    assert_equal search_results, llm.synthesize_calls.first.fetch(:search_results)
    assert_equal subscription, llm.synthesize_calls.first.fetch(:subscription)
  end

  test "requests quiz_size new questions from llm using digest content" do
    subscription = @builder.subscription
    llm = @builder.fake_llm_client(content: "Digest body for questions.")

    @builder.generate(subscription, llm_client: llm, quiz_size: 10)

    assert_equal 1, llm.generate_questions_calls.size
    call = llm.generate_questions_calls.first
    assert_equal subscription, call.fetch(:subscription)
    assert_equal "Digest body for questions.", call.fetch(:digest_content)
    assert_equal 10, call.fetch(:count)
  end

  test "persists new questions linked to digest and subscription" do
    subscription = @builder.subscription
    llm = @builder.fake_llm_client(question_count: 10)

    result = @builder.generate(subscription, llm_client: llm, quiz_size: 10)

    assert_equal 10, result.new_questions.size
    assert result.new_questions.all? { |question| question.persisted? }
    assert result.new_questions.all? { |question| question.digest_id == result.digest.id }
    assert result.new_questions.all? { |question| question.topic_subscription_id == subscription.id }
  end

  test "returns result with digest quiz and new questions" do
    subscription = @builder.subscription

    result = @builder.generate(subscription)

    assert_instance_of DigestGenerator::Result, result
    assert_equal result.digest, result.quiz.digest
    assert_equal 10, result.new_questions.size
  end

  test "integrates with QuizAssembler using only new questions on first digest" do
    subscription = @builder.subscription
    llm = @builder.fake_llm_client(question_count: 10)

    result = @builder.generate(subscription, llm_client: llm, quiz_size: 10)

    assert result.quiz.pending?
    assert_equal 10, result.quiz.quiz_questions.count
    assert_equal 10, result.quiz.quiz_questions.new_material.count
    assert_equal 0, result.quiz.quiz_questions.review.count
  end

  test "integrates with ReviewQuestionPicker when subscription has quiz history" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: Array.new(10) { { answered_correctly: true } },
      completed_at: 1.day.ago
    )
    llm = @builder.fake_llm_client(question_count: 10)

    result = @builder.generate(
      subscription,
      llm_client: llm,
      quiz_size: 10,
      published_on: Date.current
    )

    assert_equal 10, result.quiz.quiz_questions.count
    assert_equal 7, result.quiz.quiz_questions.new_material.count
    assert_equal 3, result.quiz.quiz_questions.review.count
  end

  test "excludes newly generated questions from review slots" do
    subscription = @builder.subscription
    @builder.past_quiz_with_questions(
      subscription,
      questions: [{ answered_correctly: false }],
      completed_at: 1.day.ago
    )
    llm = @builder.fake_llm_client(question_count: 10)

    result = @builder.generate(subscription, llm_client: llm, quiz_size: 10)

    new_question_ids = result.new_questions.map(&:id)
    review_question_ids = result.quiz.quiz_questions.review.pluck(:question_id)

    assert_empty new_question_ids & review_question_ids
  end

  test "updates subscription last_activity_at" do
    subscription = @builder.subscription
    subscription.update!(last_activity_at: 2.days.ago)

    travel_to Time.current do
      @builder.generate(subscription)

      assert_in_delta Time.current, subscription.reload.last_activity_at, 1.second
    end
  end

  test "raises AlreadyGenerated when digest exists for published_on" do
    subscription = @builder.subscription
    subscription.digests.create!(
      published_on: Date.current,
      status: :ready,
      content: "Existing digest",
      sources: []
    )

    assert_raises(DigestGenerator::AlreadyGenerated) do
      @builder.generate(subscription, published_on: Date.current)
    end
  end

  test "marks digest failed and re-raises when search fails" do
    subscription = @builder.subscription
    search = FailingSearchClient.new

    error = assert_raises(Search::Client::Error) do
      @builder.generate(subscription, search_client: search)
    end

    assert_equal "search unavailable", error.message
    digest = subscription.digests.find_by!(published_on: Date.current)
    assert digest.failed?
  end

  test "marks digest failed and re-raises when llm synthesis fails" do
    subscription = @builder.subscription
    llm = FailingLlmSynthesizeClient.new

    error = assert_raises(Llm::Client::Error) do
      @builder.generate(subscription, llm_client: llm)
    end

    assert_equal "synthesis failed", error.message
    digest = subscription.digests.find_by!(published_on: Date.current)
    assert digest.failed?
  end

  test "marks digest failed and re-raises when llm question generation fails" do
    subscription = @builder.subscription
    llm = FailingLlmQuestionsClient.new

    error = assert_raises(Llm::Client::Error) do
      @builder.generate(subscription, llm_client: llm)
    end

    assert_equal "question generation failed", error.message
    digest = subscription.digests.find_by!(published_on: Date.current)
    assert digest.failed?
  end

  test "generated quiz can be completed via RecordQuizCompletion" do
    subscription = @builder.subscription(streak_count: 0)
    llm = @builder.fake_llm_client(question_count: 4)

    result = @builder.generate(subscription, llm_client: llm, quiz_size: 4)
    quiz = result.quiz
    quiz.update!(status: :in_progress)

    quiz.quiz_questions.each do |quiz_question|
      quiz.question_attempts.create!(
        user: @builder.user,
        question: quiz_question.question,
        selected_index: quiz_question.question.correct_index
      )
    end

    completion = RecordQuizCompletion.call(quiz: quiz, user: @builder.user)

    assert completion.quiz.completed?
    assert_equal 100, completion.quiz.score
    assert completion.fitness.score >= 0
  end
end
