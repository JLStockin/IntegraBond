class CreateValuables < ActiveRecord::Migration
	def change
		create_table :valuables do |t|
			t.string	:type
			t.integer	:transaction_id
			t.string	:machine_state
			t.integer	:value_cents
			t.string	:origin
			t.string	:disposition
			t.string	:_data

			t.timestamps
		end
	end
end
