class CreateTopicSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :topic_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.string :cadence, null: false, default: "daily"
      t.string :knowledge_level, null: false, default: "beginner"
      t.text :goal, null: false
      t.decimal :fitness_score, precision: 5, scale: 2, null: false, default: 0
      t.integer :streak_count, null: false, default: 0
      t.datetime :last_activity_at
      t.integer :weekly_on, null: false, default: 0

      t.timestamps
    end

    add_index :topic_subscriptions, [ :user_id, :topic_id ], unique: true
  end
end
