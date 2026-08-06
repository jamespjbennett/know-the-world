class RecordQuizCompletion
  class AttemptValidator
    def initialize(quiz, user)
      @quiz = quiz
      @user = user
    end

    def validate!
      raise IncompleteAttempts if missing_attempts?
    end

    private

    def missing_attempts?
      (question_ids - attempted_question_ids).any?
    end

    def question_ids
      @quiz.questions.pluck(:id)
    end

    def attempted_question_ids
      @quiz.question_attempts.where(user: @user).pluck(:question_id)
    end
  end
end
