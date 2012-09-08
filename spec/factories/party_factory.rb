module IBContracts
module Bet
end
end

FactoryGirl.define do

	######################################################################
	#
	# Party 
	#
	factory :party1, class: Party do |party|

		party.user			FactoryGirl.build(:buyer_user)
	end

	factory :party2, class: Party do |party|

		party.user			FactoryGirl.build(:seller_user)
	end
end
