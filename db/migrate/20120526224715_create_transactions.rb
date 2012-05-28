class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.integer :contract_id
      t.integer :prior_transaction_id
      t.integer :party_of_origin_id
      t.string :status

      t.timestamps
    end
  end
end
