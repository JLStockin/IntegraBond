class CreateArtifacts < ActiveRecord::Migration
	def change
		create_table :artifacts do |t|
			t.string	:type
			t.integer	:tranzaction_id
			t.integer	:goal_id
			t.integer	:origin_id
			t.text		:_ar_data

			t.timestamps
		end

		add_index :artifacts, :tranzaction_id
	end
end
