class CreateContractClauses < ActiveRecord::Migration
  def change
    create_table :contract_clauses do |t|
      t.integer :contract_id
      t.integer :clause_id

      t.timestamps
    end

	add_index :contract_clauses, :contract_id
	add_index :contract_clauses, :clause_id
  end
end
