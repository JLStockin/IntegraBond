class CreateValuables < ActiveRecord::Migration
	def change
		create_table :valuables do |t|
			t.integer	:transaction_id
			t.string	:xasset
			t.string	:description
			t.string	:more_description

			t.timestamps
		end
	end
end
