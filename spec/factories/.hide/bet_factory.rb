
FactoryGirl.define do

	######################################################################
	#
	# 
	#
	factory :"ib_contracts/bet/contract_no_goodies", class: IBContracts::Bet::ContractBet, \
		parent: :transaction do |trans1|

		factory :"ib_contracts/bet/contract_bet", class: IBContracts::Bet::ContractBet, \
			parent: :transaction do |trans2|

			after(:build) do |transaction|
				transaction.parties << FactoryGirl.build(\
					:"ib_contracts/bet/party_party1", transaction: transaction, \
					parent: Party)

				transaction.valuables << FactoryGirl.build(\
					:"ib_contracts/bet/valuable_party1_bet", transaction: transaction, \
					parent: Valuable)

				transaction.valuables << FactoryGirl.build(\
					:"ib_contracts/bet/valuable_party1_fees", transaction: transaction, \
					parent: Valuable)
			end
		end
	end

	######################################################################
	#
	# Goal
	#
	factory :"ib_contracts/bet/goal_accept, class IBContracts::Bet::GoalAccept,
		parent: Goal do |goal|

	end

	######################################################################
	#
	# Artifact 
	#
	factory :"ib_contracts/bet/artifact_results, class: IBContracts::Bet::ArtifactResults, \
		parent: Artifact do |artifact|
		artifact.type			lambda {self.class}
		artifact.sender			:system
		artifact.receiver		[:PartyParty1, :PartyParty2]	
		artifact.description	"Results are in"

	end

	factory :"ib_contracts/bet/artifact_accept, class: IBContracts::Bet::ArtifactAccept, \
		parent: Artifact do |artifact|
		artifact.type			lambda {self.class}
		artifact.sender			:system
		artifact.receiver		:PartyParty2	
		artifact.description	"Bets up!"

	end

end
