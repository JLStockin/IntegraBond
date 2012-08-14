class CreateDisputes < ActiveRecord::Migration
  def up
    create_table :disputes do |t|
	  t.integer	:transaction_id 
      t.string	:claimant
      t.string	:counterparty
      t.text	:allegation
      t.text	:response

      t.timestamps
    end

	add_index :disputes, :transaction_id
  end

  def down
	drop_table :disputes
  end
end
