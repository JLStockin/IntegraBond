class CreateUsers < ActiveRecord::Migration
	def change
		create_table :users do |t|
			t.string	:first_name
			t.string	:last_name
			t.string	:email
			t.integer	:normalized_phone
			t.text		:_ar_data
			t.string	:encrypted_password
			t.string	:salt
			t.boolean	:admin, :default => false

			t.timestamps
		end

		add_index :users, :email, :unique => true	
		add_index :users, :normalized_phone, :unique => true	
	end
end
