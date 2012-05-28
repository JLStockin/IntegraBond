class CreateObligationValuables < ActiveRecord::Migration
  def change
    create_table :obligation_valuables do |t|
      t.integer :obligation_id
      t.integer :valuable_id

      t.timestamps
    end

	create_index :obligation_valuables, :obligation_id
	create_index :obligation_valuables, :valuable_id
  end
end
