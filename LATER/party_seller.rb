module IBContracts::CL

	class PartySeller < Party

		def bonded?
			transaction.valuable(ValuableSellerDeposit).nil? \
				or transaction.valuable(ValuableSellerFees.nil? ? false : true
		end

	end

end
