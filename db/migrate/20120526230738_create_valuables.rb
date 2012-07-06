class CreateValuables < ActiveRecord::Migration
  def change
    create_table :valuables do |t|
      t.string :description
      t.string :more_description
      t.integer :xasset_id
      t.integer :transaction_id
      t.integer :grantee
      t.integer :grantor
#      t.integer :trustee

      t.timestamps
    end
  end
end
