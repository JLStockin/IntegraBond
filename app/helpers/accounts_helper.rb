module AccountsHelper

	#
	# Return the textual representation of the Xaction OP code.
	# For the time being, just report what's returned by the data layer.
	# Eventually, this data should come from the view layer.
	#
	def op_for(xaction)
		Xaction::TRANSACTION_ACCOUNT_OPS[xaction.op.to_sym][0]
	end

end
