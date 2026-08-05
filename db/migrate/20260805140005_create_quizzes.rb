class CreateQuizzes < ActiveRecord::Migration[8.1]
  def change
    create_table :quizzes do |t|
      t.references :digest, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "pending"
      t.integer :score
      t.datetime :completed_at

      t.timestamps
    end

    add_index :quizzes, :status
  end
end
