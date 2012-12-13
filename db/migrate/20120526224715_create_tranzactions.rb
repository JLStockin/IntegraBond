class CreateTranzactions < ActiveRecord::Migration
  def change
    create_table	:tranzactions do |t|
      t.string		:type	# contract class
	  t.integer		:originator_id	# Party initiating transaction
	  t.text		:_ar_data # yaml'd hash
	  t.string		:wizard_step

      t.timestamps
    end
  end
end
