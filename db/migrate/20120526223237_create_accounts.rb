class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :user_id
      t.string :name
      t.integer :funds_cents,		:default => 0, :null => false
      t.integer :hold_funds_cents,	:default => 0, :null => false
	  t.string	:funds_currency

      t.timestamps
    end

	add_index :accounts, :user_id
  end
end
