require "test_helper"

# Search::QueryBuilder specification
#
# Public interface:
#   Search::QueryBuilder.for(subscription) => String
#
# Builds a web search query from the subscription's topic, goal, and knowledge level.
#
class SearchQueryBuilderTest < ActiveSupport::TestCase
  setup do
    @builder = DigestGeneratorScenarioBuilder.new
  end

  test "includes topic name goal and knowledge level" do
    subscription = @builder.subscription(
      goal: "Stay current on breakthroughs",
      knowledge_level: :intermediate
    )

    query = Search::QueryBuilder.for(subscription)

    assert_includes query, subscription.topic.name
    assert_includes query, "Stay current on breakthroughs"
    assert_includes query, "intermediate"
  end

  test "includes beginner knowledge level by default" do
    subscription = @builder.subscription

    query = Search::QueryBuilder.for(subscription)

    assert_includes query, "beginner"
  end
end
