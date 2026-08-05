class ReviewQuestionPicker
  def self.call(subscription, count:, excluding: [])
    new(subscription, count, excluding).call
  end

  def initialize(subscription, count, excluding)
    @subscription = subscription
    @count = count
    @excluding = excluding
  end

  def call
    sorted_candidates.first(@count)
  end

  private

  def sorted_candidates
    candidates.sort_by { |question| [ priority.rank(question), question.id ] }
  end

  def priority
    @priority ||= QuestionPriority.new(@subscription)
  end

  def candidates
    bank.completed_questions.reject { |question| excluded?(question) }
  end

  def excluded?(question)
    @excluding.include?(question.id)
  end

  def bank
    QuestionBank.new(@subscription)
  end
end
