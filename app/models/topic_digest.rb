class TopicDigest < ApplicationRecord
  self.table_name = "digests"

  belongs_to :topic_subscription

  has_one :quiz, dependent: :destroy, foreign_key: :digest_id
  has_many :questions, dependent: :nullify, foreign_key: :digest_id

  enum :status, {
    pending: "pending",
    generating: "generating",
    ready: "ready",
    failed: "failed"
  }, validate: true

  validates :published_on, presence: true
  validates :published_on, uniqueness: { scope: :topic_subscription_id }
end
