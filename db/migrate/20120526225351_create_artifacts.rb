class CreateArtifacts < ActiveRecord::Migration
	def change
		create_table :artifacts do |t|
			t.string	:type
			t.integer	:transaction_id
			t.integer	:sender_id
			t.integer	:receiver_id
			t.string	:_data

			t.timestamps
		end

		add_index :artifacts, :transaction_id
	end
end
