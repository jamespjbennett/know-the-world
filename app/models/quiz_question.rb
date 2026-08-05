class QuizQuestion < ApplicationRecord
  belongs_to :quiz
  belongs_to :question

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :question_id, uniqueness: { scope: :quiz_id }
  validates :position, uniqueness: { scope: :quiz_id }

  scope :review, -> { where(review: true) }
  scope :new_material, -> { where(review: false) }
end
