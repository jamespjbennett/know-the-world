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
      payload
        .slice(:prompt, :options, :correct_index, :explanation)
        .merge(digest: @digest)
    end
  end
end
