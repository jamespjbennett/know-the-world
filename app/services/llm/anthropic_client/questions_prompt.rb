module Llm
  class AnthropicClient
    module QuestionsPrompt
      module_function

      def system
        <<~PROMPT
          You write multiple-choice questions for a learning app.
          Each question has exactly 4 options and one correct answer.
          correct_index is 0-based.
          Base questions only on the digest content.
          Respond with JSON only, no markdown fences, shaped as:
          {"questions":[{"prompt":"...","options":["A","B","C","D"],"correct_index":0,"explanation":"..."}]}
        PROMPT
      end

      def user(subscription, digest_content, count)
        <<~PROMPT
          Topic: #{subscription.topic.name}
          Knowledge level: #{subscription.knowledge_level}
          Generate exactly #{count} questions.

          Digest:
          #{digest_content}
        PROMPT
      end
    end
  end
end
