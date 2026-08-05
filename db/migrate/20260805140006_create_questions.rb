class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :topic_subscription, null: false, foreign_key: true
      t.references :digest, foreign_key: true
      t.text :prompt, null: false
      t.jsonb :options, null: false, default: []
      t.integer :correct_index, null: false
      t.text :explanation, null: false

      t.timestamps
    end
  end
end
