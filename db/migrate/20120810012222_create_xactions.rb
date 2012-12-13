class CreateXactions < ActiveRecord::Migration
  def change
    create_table	:xactions do |t|
      t.string		:op
      t.integer		:primary_id
      t.integer		:beneficiary_id
      t.integer		:amount_cents
      t.integer		:hold_cents

      t.timestamps
    end

	add_index :xactions, :primary_id
	add_index :xactions, :beneficiary_id
  end
end
