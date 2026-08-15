class DigestGenerator
  class QuestionPersister
    def initialize(subscription, digest)
      @subscription = subscription
      @digest = digest
    end

    def persist(payloads)
      payloads.map { |payload| create!(payload) }
    end

    private

    def create!(payload)
      @subscription.questions.create!(attrs(payload))
    end

    def attrs(payload)
      normalize(payload)
        .slice(:prompt, :options, :correct_index, :explanation)
        .merge(digest: @digest)
    end

    def normalize(payload)
      payload.to_h.with_indifferent_access
    end
  end
end
