class CreateValuables < ActiveRecord::Migration
	def change
		create_table :valuables do |t|
			t.string	:type
			t.integer	:contract_id
			t.string	:machine_state
			t.integer	:value_cents

			t.integer	:origin_id
			t.integer	:disposition_id
			t.string	:_ar_data

			t.timestamps
		end
	end
end
