class CreateClauses < ActiveRecord::Migration
  def change
    create_table :clauses do |t|
      t.string :ruby_module
      t.string :author
      t.string :state
      t.string :relative_t1
      t.string :relative_t2

      t.timestamps
    end
  end
end
