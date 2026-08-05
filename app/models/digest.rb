class Digest < ApplicationRecord
  belongs_to :topic_subscription

  has_one :quiz, dependent: :destroy
  has_many :questions, dependent: :nullify

  enum :status, {
    pending: "pending",
    generating: "generating",
    ready: "ready",
    failed: "failed"
  }, validate: true

  validates :published_on, presence: true
  validates :published_on, uniqueness: { scope: :topic_subscription_id }
end
