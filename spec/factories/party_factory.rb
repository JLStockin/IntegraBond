module IBContracts
module Test 
end
end

FactoryGirl.define do

	######################################################################
	#
	# Party 
	#
	factory :party1, class: Party do |party|
		association	:user,			factory: :buyer_user
		association :contract,		factory: :test_contract		
	end

	factory :party2, class: Party do |party|
		association	:user,			factory: :seller_user
		association :contract,		factory: :test_contract		
	end
end
