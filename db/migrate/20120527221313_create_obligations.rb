class CreateObligations < ActiveRecord::Migration
  def change
    create_table :obligations do |t|
      t.integer :transaction_id
      t.integer :clause_id
	  t.string  :state
	  t.string	:milestones

      t.timestamps
    end

	add_index :obligations, :transaction_id
  end
end
