class CreateInvitations < ActiveRecord::Migration
	def change
		create_table :invitations do |t|
			t.string	:type

			t.integer	:party_id
			t.string	:slug

			t.timestamps
		end

		add_index :invitations, :party_id
		add_index :invitations, :slug
	end
end
