class CreateParties < ActiveRecord::Migration
  def change
    create_table :parties do |t|
	  t.string  :type
      t.integer :user_id
      t.integer :transaction_id
      t.string	:role

      t.timestamps
    end

	add_index :parties, :transaction_id
  end
end
