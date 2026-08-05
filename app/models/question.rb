class Question < ApplicationRecord
  OPTION_COUNT = 4

  belongs_to :topic_subscription
  belongs_to :digest, optional: true

  has_many :quiz_questions, dependent: :destroy
  has_many :quizzes, through: :quiz_questions
  has_many :question_attempts, dependent: :destroy

  validates :prompt, presence: true
  validates :explanation, presence: true
  validates :correct_index, numericality: { only_integer: true, in: 0..(OPTION_COUNT - 1) }
  validate :options_format

  def correct_option
    options[correct_index]
  end

  private

  def options_format
    unless options.is_a?(Array) && options.length == OPTION_COUNT && options.all?(String)
      errors.add(:options, "must be an array of #{OPTION_COUNT} strings")
    end
  end
end
