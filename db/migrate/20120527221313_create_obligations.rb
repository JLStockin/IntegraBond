class CreateObligations < ActiveRecord::Migration
  def change
    create_table :obligations do |t|
      t.integer :transaction_id
      t.integer :clause_id
      t.integer :t1
      t.integer :t2

      t.timestamps
    end

	create_index :obligations, :transaction_id
  end
end
