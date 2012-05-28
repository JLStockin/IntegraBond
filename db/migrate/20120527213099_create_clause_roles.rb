class CreateClauseRoles < ActiveRecord::Migration
  def change
    create_table :clause_roles do |t|
      t.integer :clause_id
      t.integer :role_id

      t.timestamps
    end

	create_index :clause_roles, :clause_id
	create_index :clause_roles, :role_id
  end
end
