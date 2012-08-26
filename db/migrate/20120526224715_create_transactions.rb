class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string		:type	# contract class
      t.integer		:prior_transaction_id
	  t.string		:author_email
	  t.string		:machine_state
	  t.string		:role_of_origin
	  t.string		:_data # yaml'd hash

      t.timestamps
    end
  end
end
