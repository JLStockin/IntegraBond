class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :user_id
      t.float :available_funds
      t.float :total_funds

      t.timestamps
    end

	add_index :accounts, :user_id
  end
end
