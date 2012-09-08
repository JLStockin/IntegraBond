
FactoryGirl.define do

	######################################################################
	#
	# Contract 
	#
	factory :test_contract, class: Contract do |transaction|
		# Stuff specific to this contract 
		transaction.goals		{}
		transaction.artifacts	{}
		transaction.valuables	{}
	end

end

