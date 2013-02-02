class CreateValuables < ActiveRecord::Migration
	def change
		create_table :valuables do |t|
			t.string	:type
			t.integer	:tranzaction_id
			t.string	:machine_state
			t.integer	:value_cents, :default => 0, :null => false
			t.string	:currency, :null => false

			t.integer	:origin_id
			t.integer	:disposition_id
			t.text		:_ar_data

			t.timestamps
		end
	end
end
