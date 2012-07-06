class CreateEvidences < ActiveRecord::Migration
  def change
    create_table :evidences do |t|
      t.string :evidence_type
      t.string :source
      t.string :description
      t.integer :obligation_id

      t.timestamps
    end

	add_index :evidences, :obligation_id
  end
end
