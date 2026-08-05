class Quiz < ApplicationRecord
  belongs_to :digest, class_name: "TopicDigest"

  has_many :quiz_questions, -> { order(:position) }, dependent: :destroy
  has_many :questions, through: :quiz_questions
  has_many :question_attempts, dependent: :destroy

  enum :status, {
    pending: "pending",
    in_progress: "in_progress",
    completed: "completed"
  }, validate: true

  validates :score, numericality: { only_integer: true, in: 0..100 }, allow_nil: true

  delegate :topic_subscription, to: :digest
end
