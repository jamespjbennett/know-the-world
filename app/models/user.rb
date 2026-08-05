class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :topic_subscriptions, dependent: :destroy
  has_many :topics, through: :topic_subscriptions
  has_many :custom_topics, class_name: "Topic", dependent: :destroy, inverse_of: :user
  has_many :question_attempts, dependent: :destroy

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
end
