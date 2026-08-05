class FitnessSnapshot < ApplicationRecord
  belongs_to :topic_subscription

  validates :score, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :recorded_on, presence: true
  validates :recorded_on, uniqueness: { scope: :topic_subscription_id }
end
