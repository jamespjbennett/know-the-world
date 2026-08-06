class RecordQuizCompletion
  class QuizScoreCalculator
    def self.for(quiz, user:)
      new(quiz, user).score
    end

    def initialize(quiz, user)
      @quiz = quiz
      @user = user
    end

    def score
      return 0 if total.zero?

      (correct_count * 100.0 / total).round
    end

    private

    def correct_count
      attempts.count(&:correct?)
    end

    def total
      @quiz.questions.count
    end

    def attempts
      @quiz.question_attempts.where(user: @user).to_a
    end
  end
end
