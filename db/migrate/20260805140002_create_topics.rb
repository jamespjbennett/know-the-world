class CreateTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :curated, null: false, default: false
      t.jsonb :profile, null: false, default: {}
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :topics, :curated
    add_index :topics, [ :user_id, :name ], unique: true, where: "user_id IS NOT NULL"
    add_index :topics, :name, unique: true, where: "curated = true"
  end
end
