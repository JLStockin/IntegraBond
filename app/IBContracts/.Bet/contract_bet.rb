###################################################################################
#
#

module IBContracts; end

module IBContracts::Bet

	class ContractBet < Contract::Base 

		# Stuff specific to this contract 
		VERSION = "0.1"
		CONTRACT_NAME = "Test Contract; bet between two parties"
		SUMMARY = "Bet between two parties.  Bet is bond amount."

		AUTHOR_EMAIL = "cschille@gmail.com" 
		PARTIES = [{:Party1 => "First Party"}, {:Party2 => "Second Party"}]
		VALUABLES = [ \
			{:Party1Bet => "First Party's bet money"},
			{:Party2Bet => "Second Party's bet money"},
			{:Party1Fees => "Transaction fees for First Party"},
			{:Party2Fees => "Transcation fees for Second Party"}\
		]
		GOALS = [:GoalAccept]
		ARTIFACTS = [:Offer, :ArtifactAccept, :ArtifactDecline, :ArtifactOutcome]

		DEFAULT_BOND = {:Party1 => Money.parse("$20"), :Party2 => Money.parse("$20")}

	end

end # IBContracts::Bet
