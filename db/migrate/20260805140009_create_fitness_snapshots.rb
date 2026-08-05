class CreateFitnessSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :fitness_snapshots do |t|
      t.references :topic_subscription, null: false, foreign_key: true
      t.decimal :score, precision: 5, scale: 2, null: false
      t.date :recorded_on, null: false

      t.timestamps
    end

    add_index :fitness_snapshots, [ :topic_subscription_id, :recorded_on ], unique: true
  end
end
