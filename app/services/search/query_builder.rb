module Search
  class QueryBuilder
    def self.for(subscription)
      new(subscription).to_query
    end

    def initialize(subscription)
      @subscription = subscription
    end

    def to_query
      parts.join(" ")
    end

    private

    def parts
      [topic_name, goal, knowledge_level]
    end

    def topic_name
      @subscription.topic.name
    end

    def goal
      @subscription.goal
    end

    def knowledge_level
      @subscription.knowledge_level
    end
  end
end
