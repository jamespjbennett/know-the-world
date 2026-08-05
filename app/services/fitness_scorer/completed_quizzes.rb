class FitnessScorer
  class CompletedQuizzes
    def self.for(subscription)
      Quiz.completed
        .joins(:digest)
        .where(digests: { topic_subscription_id: subscription.id })
        .order(completed_at: :asc)
    end
  end
end
