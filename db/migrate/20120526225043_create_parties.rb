class CreateParties < ActiveRecord::Migration
  def change
    create_table :parties do |t|
	  t.string  :type
      t.integer :user_id
      t.integer :contract_id

      t.timestamps
    end

	add_index :parties, :contract_id
  end
end
