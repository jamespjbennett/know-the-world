class ReviewQuestionPicker
  class QuestionPriority
    def initialize(subscription)
      @subscription = subscription
    end

    def rank(question)
      answered_incorrectly?(question) ? 0 : 1
    end

    private

    def answered_incorrectly?(question)
      attempt = latest_attempt_for(question)
      attempt.present? && !attempt.correct?
    end

    def latest_attempt_for(question)
      QuestionAttempt
        .where(user_id: @subscription.user_id, question_id: question.id)
        .order(created_at: :desc)
        .first
    end
  end
end
