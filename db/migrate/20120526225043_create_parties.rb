class CreateParties < ActiveRecord::Migration
  def change
    create_table :parties do |t|
      t.integer :transaction_id
      t.string	:role
      t.integer :user_id
	  t.boolean :is_bonded
	  t.integer	:bound_amount
	  t.integer	:fees_amount

      t.timestamps
    end

	add_index :parties, :transaction_id
  end
end
