module IBContracts
module Bet
end
end

FactoryGirl.define do

	######################################################################
	#
	# Valuable 
	#
	factory :"ib_contracts/bet/party1_bet", class: IBContracts::Bet::ValuableParty1Bet, \
		parent: Valuable do |valuable|

		valuable.description		"Party1 Bet"
		valuable.more_description	""
		valuable.value				Money.parse("$20")
		valuable.origin				:PartyParty1	
		valuable.disposition		:PartyParty1	
	end

	factory :"ib_contracts/bet/party2_bet", class: IBContracts::Bet::ValuableParty2Bet, \
		parent: Valuable do |valuable|

		valuable.description		"Party2 Bet"
		valuable.more_description	""
		valuable.value				Money.parse("$20")
		valuable.origin				:PartyParty2
		valuable.disposition		:PartyParty2	
	end

	factory :"ib_contracts/bet/valuable_party1_fees", \
		class: IBContracts::Bet::ValuableParty1Fees, parent: Valuable do |valuable|

		valuable.description		"Transaction fees"
		valuable.more_description	""
		valuable.value				Money.parse("$1")
		valuable.origin				:PartyParty1
		valuable.disposition		:PartyParty1
	end

	factory :"ib_contracts/bet/valuable_party2_fees", \
		class: IBContracts::Bet::ValuableParty2Fees, parent: Valuable do |valuable|

		valuable.description		"Transaction fees"
		valuable.more_description	""
		valuable.value				Money.parse("$1")
		valuable.origin				:PartyParty2
		valuable.disposition		:PartyParty2
	end

end
