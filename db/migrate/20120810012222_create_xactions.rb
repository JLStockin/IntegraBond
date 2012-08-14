class CreateXactions < ActiveRecord::Migration
  def change
    create_table	:xactions do |t|
      t.string		:op
      t.integer		:primary_id
      t.integer		:beneficiary_id
      t.integer		:amount_cents

      t.timestamps
    end
  end
end
