class TopicSubscription < ApplicationRecord
  MAX_TOPICS_PER_USER = 3

  belongs_to :user
  belongs_to :topic

  has_many :digests, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :fitness_snapshots, dependent: :destroy

  enum :cadence, { daily: "daily", weekly: "weekly" }, validate: true
  enum :knowledge_level, {
    beginner: "beginner",
    intermediate: "intermediate",
    advanced: "advanced"
  }, validate: true, prefix: true

  validates :goal, presence: true
  validates :fitness_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :streak_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :weekly_on, inclusion: { in: 0..6 }
  validates :user_id, uniqueness: { scope: :topic_id }
  validate :user_topic_limit, on: :create

  before_validation :set_weekly_on, on: :create

  def due_on?(date = Date.current)
    case cadence
    when "daily"
      true
    when "weekly"
      date.wday == weekly_on
    else
      false
    end
  end

  private

  def set_weekly_on
    self.weekly_on ||= Time.current.wday
  end

  def user_topic_limit
    return unless user

    if user.topic_subscriptions.count >= MAX_TOPICS_PER_USER
      errors.add(:base, "You can follow at most #{MAX_TOPICS_PER_USER} topics")
    end
  end
end
