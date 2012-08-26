module IBContracts
module Bet
end
end

FactoryGirl.define do

	######################################################################
	#
	# Party 
	#
	factory :party1, class: IBContracts::Bet::PartyParty1 do |party|

		party.role			"first party"	
		party.user			FactoryGirl.build(:buyer_user)
	end

	factory :party2, class: IBContracts::Bet::PartyParty2 do |party|

		party.role			"second party"	
		party.user			FactoryGirl.build(:seller_user)
	end
end
