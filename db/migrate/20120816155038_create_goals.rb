class CreateGoals < ActiveRecord::Migration
	def change
		create_table :goals do |t|
			t.string	:type
			t.integer	:tranzaction_id
			t.string	:machine_state
			t.text		:_ar_data

			t.timestamps
		end
		add_index :goals, :tranzaction_id
	end
end
