class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.string :name
      t.integer :author_id
      t.string :summary
      t.string :tags
      t.string :ruby_module

      t.timestamps
    end
  end
end
