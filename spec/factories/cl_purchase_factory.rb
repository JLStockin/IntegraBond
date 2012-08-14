
FactoryGirl.define do

	######################################################################
	#
	# Transaction IBContracts::CLPurchase 
	#
	factory :"ib_contracts/contract_no_goodies", class: IBContracts::CLPurchase, \
		parent: :transaction do |trans|

		trans.role_of_origin :buyer	
		trans.milestones	[ appointment: {hours: 24}, late: {minutes: 15}, \
			cancel: {hours: 10}, reschedule: {hours: 4}, inspect: {minutes: 45}, \
			complaint: {minutes: 15} ]
		trans.machine_state	:s_binding	
		trans.fault			[ buyer: false, seller: false ]

		factory :"ib_contracts/cl_purchase", class: IBContracts::CLPurchase, \

			after(:build) do |transaction|
				transaction.parties << FactoryGirl.build(:seller_party, \
					transaction: transaction)
				transaction.parties << FactoryGirl.build(:buyer_party, \
					transaction: transaction)

				transaction.valuables << FactoryGirl.build(:seller_deposit, \
					transaction: transaction)
				transaction.valuables << FactoryGirl.build(:buyer_deposit, \
					transaction: transaction)
				transaction.valuables << FactoryGirl.build(:seller_goods, \
					transaction: transaction)
		end
	end

	######################################################################
	#
	# Evidence 
	#
	factory :evidence, class: Evidence do |evidence|
		evidence.evidence_type	:location_verification
		evidence.source			:system
		evidence.subject		:buyer
		evidence.description	"Buyer arrived"

		factory :buyer_assert_here do |evd|
			evd.evidence_type	:location_verification
			evd.source			:buyer
			evd.subject			:buyer
			evd.description		"Buyer says he's there"	
			evd.created_at		DateTime.now	
		end

		factory :seller_confirm_buyer_here do |evd|
			evd.evidence_type	:location_verification
			evd.source			:buyer
			evd.subject			:buyer
			evd.description		"Buyer says he's there"	
			evd.created_at		DateTime.now	
		end

		factory :seller_assert_here do |evd|
			evd.evidence_type	:location_verification
			evd.source			:buyer
			evd.subject			:buyer
			evd.description		"Buyer says he's there"	
			evd.created_at		DateTime.now	
		end

		factory :buyer_confirm_seller_here do |evd|
			evd.evidence_type	:location_verification
			evd.source			:buyer
			evd.subject			:buyer
			evd.description		"Buyer says he's there"	
			evd.created_at		DateTime.now	
		end

		factory :buyer_asserts_paid_seller	do |evd|
			evd.evidence_type	:payment_verification
			evd.source			:buyer
			evd.subject			:payment
			evd.description		"Buyer says he's paid"	
			evd.created_at		DateTime.now	
		end

		factory :seller_confirms_buyer_paid	do |evd|
			evd.evidence_type	:payment_verification
			evd.source			:seller
			evd.subject			:payment
			evd.description		"Seller says he's paid"	
			evd.created_at		DateTime.now	
		end
	end

	######################################################################
	#
	# Valuable 
	#
	factory :goods, class: Valuable do |valuable|
		valuable.description		"Rolex Watch"
		valuable.more_description	"Authentic Rolex P55 paratrooper-wanabee "\
			+ "in excellent condition"
		valuable.value				Money.new(200, "USD")
		valuable.assigned_to		:seller	 
		valuable.xasset				:seller_goods

	end

	factory :buyer_deposit, class: Valuable do |valuable|
		valuable.description		"Buyer Deposit"
		valuable.more_description	""
		valuable.value				Money.new(20, "USD")
		valuable.assigned_to		:buyer
		valuable.xasset				:buyer_deposit
	end

	factory :seller_deposit, class: Valuable do |valuable|
		valuable.description		"Seller Deposit"
		valuable.more_description	""
		valuable.value				Money.new(20, "USD")
		valuable.assigned_to		:seller	 
	end

	factory :seller_fees, class: Valuable do |valuable|
		valuable.description		"Seller's share of fees"
		valuable.more_description	""
		valuable.value				Money.new(1, "USD")
		valuable.assigned_to		:seller
	end

	factory :buyer_fees, class: Valuable do |valuable|
		valuable.description		"Buyer's share of fees"
		valuable.more_description	""
		valuable.value				Money.new(1, "USD")
		valuable.assigned_to		:buyer
	end

	######################################################################
	#
	# Party 
	#
	factory :buyer_party, class: Party do |party|
		party.role			:buyer
		party.user			FactoryGirl.build(:buyer_user)
		party.is_bonded		false
		party.bond_amount	Money.new(20)	
		party.fees_amount	Money.new(1)	
	end

	factory :seller_party, class: Party do |party|
		party.role			:seller
		party.user			FactoryGirl.build(:seller_user)
		party.is_bonded		false
		party.bond_amount	Money.new(20)	
		party.fees_amount	Money.new(1)	
	end
end
