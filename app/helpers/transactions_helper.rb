module TransactionsHelper

	#
	# Pull in contract-specific view helpers
	#
	Dir[Rails.root.join('app', 'views', 'ib_contracts', '*')].each do |prj_dir|
		Dir[File.join(prj_dir, '*.rb')].each do |file|
			require file
		end
	end

end
