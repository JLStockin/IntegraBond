class CreateApples < ActiveRecord::Migration
	def change
		create_table :apples do |t|
			t.string	:type
			t.string	:machine_state
			t.string	:_data

			t.timestamps
		end
	end
end
