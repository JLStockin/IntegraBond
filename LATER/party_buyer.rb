module IBContracts::CL

	class PartyBuyer < Party

		def bonded?
			transaction.valuable(ValuableBuyerDeposit).nil? ? false : true
		end

	end

end
