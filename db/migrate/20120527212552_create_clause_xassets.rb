class CreateClauseXassets < ActiveRecord::Migration
  def change
    create_table :clause_xassets do |t|
      t.integer :clause_id
      t.integer :xasset_id

      t.timestamps
    end

	create_index :clause_xassets, :clause_id
	create_index :clause_xassets, :xasset_id
  end
end
