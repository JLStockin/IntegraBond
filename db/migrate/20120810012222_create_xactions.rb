class CreateXactions < ActiveRecord::Migration
	def change
		create_table	:xactions do |t|
			t.string	:op
			t.integer	:primary_id
			t.integer	:beneficiary_id
			t.integer	:amount_cents, :default => 0, :null => false
			t.integer	:hold_cents, :default => 0, :null => false
			t.string	:currency, :null => false

			t.timestamps
		end

		add_index :xactions, :primary_id
		add_index :xactions, :beneficiary_id
	end
end
