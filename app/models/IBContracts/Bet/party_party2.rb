module IBContracts
end

module IBContracts::Bet

	class PartyParty2< Party

		def bonded?
			transaction.valuable(:ValuableParty2Deposit).nil? ? false : true
		end

	end

end
