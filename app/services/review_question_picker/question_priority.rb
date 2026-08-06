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
      completed_attempts_for(question).order(created_at: :desc).first
    end

    def completed_attempts_for(question)
      QuestionAttempt.joins(:quiz).merge(Quiz.completed).where(attempt_scope(question))
    end

    def attempt_scope(question)
      { user_id: @subscription.user_id, question_id: question.id }
    end
  end
end
