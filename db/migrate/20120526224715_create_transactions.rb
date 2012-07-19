class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string		:type	# contract class
      t.integer		:prior_transaction_id
	  t.string		:author_email
      t.string		:role_of_origin
	  t.string		:milestones	# free form hash describing important DateTimes
	  t.string		:machine_state
	  t.string		:fault	# free form hash describing outcome

      t.timestamps
    end
  end
end
