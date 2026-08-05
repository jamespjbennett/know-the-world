class FitnessScorer
  class Consistency
    WEIGHT = 0.3
    DAILY_STREAK_TARGET = 7
    WEEKLY_STREAK_TARGET = 4

    def initialize(subscription)
      @subscription = subscription
    end

    def score
      [ streak_percentage, 100.0 ].min
    end

    private

    def streak_percentage
      @subscription.streak_count / streak_target.to_f * 100
    end

    def streak_target
      @subscription.daily? ? DAILY_STREAK_TARGET : WEEKLY_STREAK_TARGET
    end
  end
end
