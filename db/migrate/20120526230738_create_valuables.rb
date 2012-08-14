class CreateValuables < ActiveRecord::Migration
	def change
		create_table :valuables do |t|
			t.integer	:transaction_id
			t.integer	:value_cents
			t.string	:xasset
			t.string	:description
			t.string	:more_description
			t.string	:assigned_to

			t.timestamps
		end
	end
end
