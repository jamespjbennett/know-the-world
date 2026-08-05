class Topic < ApplicationRecord
  belongs_to :user, optional: true

  has_many :topic_subscriptions, dependent: :destroy
  has_many :subscribers, through: :topic_subscriptions, source: :user

  scope :curated, -> { where(curated: true) }
  scope :custom, -> { where(curated: false) }

  validates :name, presence: true
  validates :name, uniqueness: { scope: :user_id }, if: :custom?
  validates :name, uniqueness: true, if: :curated?

  def custom?
    !curated?
  end
end
