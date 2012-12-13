class CreateUsers < ActiveRecord::Migration
	def change
		create_table :users do |t|
			t.string	:username
			t.string	:first_name
			t.string	:last_name
			t.text		:_ar_data
			t.string	:encrypted_password
			t.string	:salt
			t.boolean	:admin, :default => false

			t.timestamps
		end

		add_index :users, :username, :unique => true	
	end
end
