# Builds subscriptions and fakes for DigestGenerator tests.
#
class DigestGeneratorScenarioBuilder
  def initialize
    @review_builder = ReviewQuestionScenarioBuilder.new
  end

  def user
    @review_builder.user
  end

  def subscription(**options)
    @review_builder.subscription(**options)
  end

  def past_quiz_with_questions(subscription, **options)
    @review_builder.past_quiz_with_questions(subscription, **options)
  end

  def fake_search_client(**options)
    FakeSearchClient.new(**options)
  end

  def fake_llm_client(**options)
    FakeLlmClient.new(**options)
  end

  def generate(subscription, **options)
    ::DigestGenerator.call(
      subscription: subscription,
      published_on: options.fetch(:published_on, Date.current),
      quiz_size: options.fetch(:quiz_size, 10),
      search_client: options.fetch(:search_client, fake_search_client),
      llm_client: options.fetch(:llm_client, fake_llm_client)
    )
  end
end
