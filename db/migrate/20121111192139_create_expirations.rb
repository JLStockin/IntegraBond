class CreateExpirations < ActiveRecord::Migration
	def change
		create_table :expirations do |t|
			t.string	:type

			t.integer	:owner_id
			t.string	:owner_type

			t.integer	:offset		# DateTime.advance(offset_units => value)
			t.string	:offset_units

									# basis_id = self.tranzaction.model_instance(class.basis_type)
			t.datetime	:value		# = class.basis_type.find(basis_id).created_at.advance(
									#		offset_units => offset
									#   )

			t.timestamps
		end

		add_index :expirations, :value
  end
end
