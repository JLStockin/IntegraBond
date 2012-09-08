class CreateGoals < ActiveRecord::Migration
	def change
		create_table :goals do |t|
			t.string	:type
			t.integer	:contract_id
			t.string	:machine_state
			t.string	:_ar_data

			t.datetime	:expires_at
			t.timestamps
		end
		add_index :goals, :expires_at
		add_index :goals, :contract_id
	end
end
