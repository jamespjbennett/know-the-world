class FitnessScorer
  class Accuracy
    WEIGHT = 0.5
    QUIZ_LIMIT = 10

    def initialize(subscription)
      @subscription = subscription
    end

    def score
      return 0.0 if recent_scores.empty?

      recent_scores.sum / recent_scores.size.to_f
    end

    private

    def recent_scores
      completed_quizzes.last(QUIZ_LIMIT).filter_map(&:score)
    end

    def completed_quizzes
      CompletedQuizzes.for(@subscription)
    end
  end
end
