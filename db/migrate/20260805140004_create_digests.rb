class CreateDigests < ActiveRecord::Migration[8.1]
  def change
    create_table :digests do |t|
      t.references :topic_subscription, null: false, foreign_key: true
      t.text :content
      t.jsonb :sources, null: false, default: []
      t.date :published_on, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :digests, [ :topic_subscription_id, :published_on ], unique: true
    add_index :digests, :status
  end
end
