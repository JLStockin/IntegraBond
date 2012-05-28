class CreateParties < ActiveRecord::Migration
  def change
    create_table :parties do |t|
      t.integer :transaction_id
      t.integer :role_id
      t.integer :user_id

      t.timestamps
    end

	add_index :parties, :transaction_id
  end
end
