FactoryGirl.define do

	######################################################################
	#
	# Transaction 
	factory :transaction do |trans|
	end

	factory :"ib_contracts/cl_purchase", class: IBContracts::CLPurchase, \
		parent: :transaction do |trans|

		# trans.role_of_origin :buyer	
		# trans.milestones	[ show: {minutes: 20}, leave: {hours: 10} ]
		# trans.machine_state	:unbound
		# trans.fault			[ buyer: false, seller: false ]

		after(:create) do |transaction|

		end

		after(:build) do |transaction|

		end
	end

	######################################################################
	#
	# Evidence 
	factory :evidence do |evidence|
		evidence.evidence_type	:location_verification
		evidence.source			:system
		evidence.description	:gps
	end

	######################################################################
	#
	# Valuable 
	factory :valuable do |valuable|
		valuable.description		= "Rolex Watch"
		valuable.more_description	= "Authentic Rolex P55 paratrooper-wanabee "\
			+ "in excellent condition"
	end

	######################################################################
	#
	# Party 
	factory :party do |party|
	end

end
