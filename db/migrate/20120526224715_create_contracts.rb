class CreateContracts < ActiveRecord::Migration
  def change
    create_table	:contracts do |t|
      t.string		:type	# contract class
	  t.integer		:originator_id		# Party initiating transaction (origin)
	  t.text		:_ar_data # yaml'd hash

      t.timestamps
    end
  end
end
