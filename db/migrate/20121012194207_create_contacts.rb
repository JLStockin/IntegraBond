class CreateContacts < ActiveRecord::Migration
	def change
		create_table :contacts do |t|
			t.string :type
			t.string :contact_data
			t.integer :user_id

			t.timestamps
		end

		add_index :contacts, :contact_data
	end
end
