module IBContracts
end

module IBContracts::Bet

	class PartyParty1 < Party

		def bonded?
			transaction.valuable(:ValuableParty1Deposit).nil? ? false : true
		end

	end

end
