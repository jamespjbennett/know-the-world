module Llm
  class AnthropicClient
    module SynthesisPrompt
      module_function

      def system
        <<~PROMPT
          You write topic briefings for a learning app called Know The World.
          Calibrate depth to the learner's knowledge level.
          Target about 500-800 words.
          Cite only sources from the provided search results.
          Respond with JSON only, no markdown fences, shaped as:
          {"content":"markdown briefing","sources":[{"title":"...","url":"..."}]}
        PROMPT
      end

      def user(subscription, search_results)
        <<~PROMPT
          Topic: #{subscription.topic.name}
          Goal: #{subscription.goal}
          Knowledge level: #{subscription.knowledge_level}

          Search results (JSON):
          #{search_results.to_json}
        PROMPT
      end
    end
  end
end
