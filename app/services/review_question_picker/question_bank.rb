class ReviewQuestionPicker
  class QuestionBank
    def initialize(subscription)
      @subscription = subscription
    end

    def completed_questions
      Question
        .where(topic_subscription_id: @subscription.id)
        .joins(quiz_questions: :quiz)
        .merge(Quiz.completed)
        .distinct
        .to_a
    end
  end
end
