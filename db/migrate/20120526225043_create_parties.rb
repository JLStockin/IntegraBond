class CreateParties < ActiveRecord::Migration
  def change
    create_table :parties do |t|
	  t.string  :type
      t.integer :contact_id
      t.integer :tranzaction_id
	  t.string	:contact_strategy

      t.timestamps
    end

	add_index :parties, :tranzaction_id
	add_index :parties, :contact_id
  end
end
