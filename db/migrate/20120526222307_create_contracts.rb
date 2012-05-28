class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.string :name
      t.string :author
      t.string :summary
      t.string :tags
      t.string :ruby_module

      t.timestamps
    end
  end
end
