class CreateEvidences < ActiveRecord::Migration
	def change
		create_table :evidences do |t|
			t.integer	:transaction_id
			t.string	:evidence_type
			t.string	:source
			t.string	:description

			t.timestamps
		end

		add_index :evidences, :transaction_id
	end
end
