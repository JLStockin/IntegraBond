
FactoryGirl.define do

	######################################################################
	#
	# Transaction IBContracts::CLPurchase 
	#
	factory :"ib_contracts/cl/contract_no_goodies", class: IBContracts::CL::CLPurchase, \
		parent: :transaction do |trans1|

		trans.role_of_origin :buyer	
		trans.goals	

		factory :"ib_contracts/cl/cl_purchase", class: IBContracts::CL::CLPurchase, \
			parent: :transaction do |trans2|

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

				transaction.goals << FactoryGirl.build(
		end
	end

	######################################################################
	#
	# Goal
	#
	factory :goal_offer, class GoalOffer, parent: Goal do |goal|

	end

	######################################################################
	#
	# Artifact 
	#
	factory :artifact_offer, class: ArtifactOffer do |artifact|
		artifact.artifact_type	:artifact_offer
		artifact.subject		:seller
		artifact.source			:buyer
		artifact.description	"buyer has made you an offer"

	end

	factory :artifact_accept, class: ArtifactAccept do |artifact|
		artifact.artifact_type	:artifact_accept
		artifact.source			:
		artifact.subject		:buyer
		artifact.description	"buyer has made you an offer"

	end
	######################################################################
	#
	# Valuable 
	#
	factory :valuable_seller_goods, class: Valuable do |valuable|
		valuable.description		"Rolex Watch"
		valuable.more_description	"Authentic Rolex P55 paratrooper-wanabee "\
			+ "in excellent condition"
		valuable.value				Money.new(200, "USD")

	end

	factory :valuable_buyer_deposit, class: Valuable do |valuable|
		valuable.description		"Buyer Deposit"
		valuable.more_description	""
		valuable.value				Money.new(20, "USD")
	end

	factory :valuable_seller_deposit, class: Valuable do |valuable|
		valuable.description		"Seller Deposit"
		valuable.more_description	""
		valuable.value				Money.new(20, "USD")
	end

	factory :valuable_fees, class: Valuable do |valuable|
		valuable.description		"Transaction fees"
		valuable.more_description	""
		valuable.value				Money.new(1, "USD")
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
