class FitnessScorer
  Result = Data.define(:score, :accuracy, :consistency, :retention)

  def self.call(subscription)
    new(subscription).call
  end

  def initialize(subscription)
    @subscription = subscription
  end

  def call
    accuracy = clamped_score_for(Accuracy)
    consistency = clamped_score_for(Consistency)
    retention = clamped_score_for(Retention)
    total = combine(accuracy, consistency, retention)
    build_result(total, accuracy, consistency, retention)
  end

  private

  def clamped_score_for(calculator)
    clamp(calculator.new(@subscription).score)
  end

  def combine(accuracy, consistency, retention)
    total = weighted_sum(accuracy, consistency, retention)
    clamp(total)
  end

  def weighted_sum(accuracy, consistency, retention)
    Accuracy::WEIGHT * accuracy +
      Consistency::WEIGHT * consistency +
      Retention::WEIGHT * retention
  end

  def clamp(value)
    value.clamp(0.0, 100.0)
  end

  def build_result(score, accuracy, consistency, retention)
    Result.new(score: score, accuracy: accuracy, consistency: consistency, retention: retention)
  end
end
