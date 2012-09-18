class CreateArtifacts < ActiveRecord::Migration
	def change
		create_table :artifacts do |t|
			t.string	:type
			t.integer	:contract_id
			t.text		:_ar_data

			t.timestamps
		end

		add_index :artifacts, :contract_id
	end
end
