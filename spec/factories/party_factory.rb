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
		association	:contact,		factory: :buyer_email_contact
		association :tranzaction,	factory: :contracts_test_test_contract
	end

	factory :party2, class: Party do |party|
		association	:contact,		factory: :seller_email_contact
		association :tranzaction,	factory: :contracts_test_test_contract
	end
end
