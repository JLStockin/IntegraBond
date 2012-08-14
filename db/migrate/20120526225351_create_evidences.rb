class CreateEvidences < ActiveRecord::Migration
	def change
		create_table :evidences do |t|
			t.integer	:transaction_id
			t.string	:hash
			t.string	:description_short
			t.string	:description_long

			t.timestamps
		end

		add_index :evidences, :transaction_id
	end
end
