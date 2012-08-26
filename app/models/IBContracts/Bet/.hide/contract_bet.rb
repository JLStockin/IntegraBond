###################################################################################
#
#

module IBContracts
end

module IBContracts::Bet

	class ContractBet < Contract::Base 

		# Stuff specific to this contract 
		VERSION = "0.1"
		CONTRACT_NAME = "Test Contract; bet between two parties"
		SUMMARY = "Bet between two parties.  Bet is bond amount."

		AUTHOR_EMAIL = "cschille@gmail.com" 
		PARTIES = [PartyParty1, PartyParty2]
		VALUABLES = [ValuableParty1Bet, ValuableParty2Bet,
			ValuableParty1Fees, ValuableParty2Fees]
		GOALS = [GoalAccept]
		ARTIFACTS = [Offer, ArtifactAccept, ArtifactDecline, ArtifactOutcome]

		DEFAULT_BOND = {PartyParty1: Money.parse("$20"), PartyParty2: Money.parse("$20")}

	end

end # IBContracts
