class CreateXassets < ActiveRecord::Migration
  def change
    create_table :xassets do |t|
      t.string :name
      t.string :asset_type

      t.timestamps
    end

  end
end
