class CreateObligationParties < ActiveRecord::Migration
  def change
    create_table :obligation_parties do |t|
      t.integer :obligation_id
      t.integer :valuable_id

      t.timestamps
    end

	create_index :obligation_parties, :obligation_id
	create_index :obligation_parties, :party_id
  end
end
