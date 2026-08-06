class QuizAssembler
  REVIEW_RATIO = 0.3

  def self.call(quiz:, new_questions:, quiz_size:)
    new(quiz, new_questions, quiz_size).call
  end

  def initialize(quiz, new_questions, quiz_size)
    @quiz = quiz
    @new_questions = new_questions
    @quiz_size = quiz_size
  end

  def call
    validate!
    assemble_unless_present
  end

  private

  def validate!
    raise ArgumentError, "duplicate new questions" if duplicate_new_questions?
    raise ArgumentError, "new questions must belong to quiz subscription" if foreign_new_questions?
  end

  def assemble_unless_present
    return @quiz if already_assembled?

    create_quiz_questions
    @quiz.reload
  end

  def already_assembled?
    @quiz.quiz_questions.exists?
  end

  def duplicate_new_questions?
    ids = @new_questions.map(&:id)
    ids.size != ids.uniq.size
  end

  def foreign_new_questions?
    @new_questions.any? { |question| question.topic_subscription_id != subscription.id }
  end

  def create_quiz_questions
    Quiz.transaction { slots.each_with_index { |slot, index| create_slot(slot, index) } }
  end

  def create_slot(slot, index)
    @quiz.quiz_questions.create!(
      question: slot.fetch(:question),
      position: index + 1,
      review: slot.fetch(:review)
    )
  end

  def slots
    new_material_slots + review_slots
  end

  def new_material_slots
    selected_new_questions.map { |question| { question: question, review: false } }
  end

  def review_slots
    review_questions.map { |question| { question: question, review: true } }
  end

  def selected_new_questions
    @new_questions.first(@quiz_size - review_questions.size)
  end

  def review_questions
    @review_questions ||= ReviewQuestionPicker.call(
      subscription,
      count: review_slot_count,
      excluding: @new_questions.map(&:id)
    )
  end

  def review_slot_count
    ReviewSlotCount.for(@quiz_size)
  end

  def subscription
    @quiz.topic_subscription
  end
end
