class QuizAssembler
  REVIEW_RATIO = 0.3

  def self.call(quiz:, subscription:, new_questions:, quiz_size:)
    new(quiz, subscription, new_questions, quiz_size).call
  end

  def initialize(quiz, subscription, new_questions, quiz_size)
    @quiz = quiz
    @subscription = subscription
    @new_questions = new_questions
    @quiz_size = quiz_size
  end

  def call
    create_quiz_questions
    @quiz.reload
  end

  private

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
      @subscription,
      count: review_slot_count,
      excluding: @new_questions.map(&:id)
    )
  end

  def review_slot_count
    ReviewSlotCount.for(@quiz_size)
  end
end
