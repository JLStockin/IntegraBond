class CreateValuables < ActiveRecord::Migration
  def change
    create_table :valuables do |t|
      t.string :description
      t.string :more_description
      t.integer :xasset_id
      t.integer :transaction_id
      t.integer :user_who_owns_id
      t.integer :user_who_will_own_id
      t.integer :user_who_now_holds_id

      t.timestamps
    end
  end
end
