class CreateQuestionAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :question_attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :quiz, null: false, foreign_key: true
      t.integer :selected_index, null: false
      t.boolean :correct, null: false

      t.timestamps
    end

    add_index :question_attempts, [ :user_id, :question_id, :quiz_id ], unique: true
  end
end
