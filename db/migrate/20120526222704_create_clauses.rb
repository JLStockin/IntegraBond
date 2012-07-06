class CreateClauses < ActiveRecord::Migration
  def change
    create_table :clauses do |t|
	  t.string :name
      t.integer :author_id
      t.string :ruby_module
      t.string :relative_milestones

      t.timestamps
    end
  end
end
