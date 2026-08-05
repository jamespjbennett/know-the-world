class FitnessScorer
  class Retention
    WEIGHT = 0.2

    def initialize(subscription)
      @subscription = subscription
    end

    def score
      return 0.0 if review_attempts.empty?

      correct_percentage
    end

    private

    def correct_percentage
      correct = review_attempts.count(&:correct?)
      correct / review_attempts.size.to_f * 100
    end

    def review_attempts
      quizzes.flat_map { |quiz| review_attempts_for(quiz) }
    end

    def quizzes
      CompletedQuizzes.for(@subscription)
    end

    def review_attempts_for(quiz)
      review_question_ids = quiz.quiz_questions.review.pluck(:question_id)
      quiz.question_attempts.where(question_id: review_question_ids).to_a
    end
  end
end
