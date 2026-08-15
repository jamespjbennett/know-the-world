require "test_helper"

class LlmAnthropicClientTest < ActiveSupport::TestCase
  setup do
    @subscription = DigestGeneratorScenarioBuilder.new.subscription(
      goal: "Track policy changes",
      knowledge_level: :beginner
    )
    @search_results = [
      { title: "Wire", url: "https://example.com/wire", snippet: "Policy update." }
    ]
  end

  test "synthesize returns content and sources from model JSON" do
    messenger = FakeMessenger.new(
      text: {
        content: "Briefing body.",
        sources: [{ title: "Wire", url: "https://example.com/wire" }]
      }.to_json
    )
    client = Llm::AnthropicClient.new(messenger: messenger, api_key: "test-key")

    result = client.synthesize(subscription: @subscription, search_results: @search_results)

    assert_equal "Briefing body.", result.fetch(:content)
    assert_equal [{ "title" => "Wire", "url" => "https://example.com/wire" }], result.fetch(:sources)
    assert_includes messenger.last_user_prompt, "Wire"
    assert_includes messenger.last_user_prompt, @subscription.topic.name
  end

  test "generate_questions returns MCQ hashes for the requested count" do
    questions = [
      {
        prompt: "What changed?",
        options: %w[A B C D],
        correct_index: 1,
        explanation: "Because B."
      }
    ]
    messenger = FakeMessenger.new(text: { questions: questions }.to_json)
    client = Llm::AnthropicClient.new(messenger: messenger, api_key: "test-key")

    result = client.generate_questions(
      subscription: @subscription,
      digest_content: "Digest body.",
      count: 1
    )

    assert_equal 1, result.size
    assert_equal "What changed?", result.first.fetch(:prompt)
    assert_equal 1, result.first.fetch(:correct_index)
    assert_includes messenger.last_user_prompt, "Digest body."
  end

  test "strips markdown fences before parsing JSON" do
    payload = { content: "Fenced", sources: [] }.to_json
    messenger = FakeMessenger.new(text: "```json\n#{payload}\n```")
    client = Llm::AnthropicClient.new(messenger: messenger, api_key: "test-key")

    result = client.synthesize(subscription: @subscription, search_results: [])

    assert_equal "Fenced", result.fetch(:content)
  end

  test "raises Llm::Client::Error when messenger fails" do
    messenger = FakeMessenger.new(error: StandardError.new("api down"))
    client = Llm::AnthropicClient.new(messenger: messenger, api_key: "test-key")

    error = assert_raises(Llm::Client::Error) do
      client.synthesize(subscription: @subscription, search_results: [])
    end

    assert_match(/api down/, error.message)
  end

  test "raises Llm::Client::Error when JSON is invalid" do
    messenger = FakeMessenger.new(text: "not-json")
    client = Llm::AnthropicClient.new(messenger: messenger, api_key: "test-key")

    assert_raises(Llm::Client::Error) do
      client.synthesize(subscription: @subscription, search_results: [])
    end
  end

  class FakeMessenger
    attr_reader :last_system_prompt, :last_user_prompt

    def initialize(text: nil, error: nil)
      @text = text
      @error = error
    end

    def complete(system:, user:)
      raise @error if @error

      @last_system_prompt = system
      @last_user_prompt = user
      @text
    end
  end
end
