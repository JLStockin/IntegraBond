class CreateObligationParties < ActiveRecord::Migration
  def change
    create_table :obligation_parties do |t|
      t.integer :obligation_id
      t.integer :party_id

      t.timestamps
    end

	add_index :obligation_parties, :obligation_id
	add_index :obligation_parties, :party_id
  end
end
