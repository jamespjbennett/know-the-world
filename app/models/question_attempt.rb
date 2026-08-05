class QuestionAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :question
  belongs_to :quiz

  validates :selected_index, numericality: { only_integer: true, in: 0..(Question::OPTION_COUNT - 1) }
  validates :question_id, uniqueness: { scope: [ :user_id, :quiz_id ] }

  before_validation :set_correctness

  private

  def set_correctness
    self.correct = selected_index == question&.correct_index
  end
end
