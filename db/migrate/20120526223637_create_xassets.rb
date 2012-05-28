class CreateXAssets < ActiveRecord::Migration
  def change
    create_table :xassets do |t|
      t.string :name
      t.string :type
      t.integer :origination_role_id
      t.integer :destination_role_id

      t.timestamps
    end

  end
end
