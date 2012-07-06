FactoryGirl.define do

	######################################################################
	#
	# Account, User
	factory :account do |account|
		name	"default"
	end

	factory :user_without_account, class: User do

		first_name		{ FactoryGirl.generate(:first_name) }
		last_name		{ FactoryGirl.generate(:last_name) }
		email			{ FactoryGirl.generate(:email) }

		password				{ "foobar" }
		password_confirmation	{ "foobar" }

		factory :user do |user|

			after(:build) do |user, context|
				attr = FactoryGirl.attributes_for(:account)
				user.build_account(attr)
			end

		end

	end

	######################################################################
	#
	# Clauses 
	factory :acceptance_clause, class: Clause do
		name					{ "Accept Contract" }
		ruby_module				{ :AcceptContract }
		relative_milestones		[ { :acceptance => {:hours => 24} } ]
	end
	factory :appointment_clause, class: Clause do
		name					{ "Appointment" }
		ruby_module				{ :Appointment}
		relative_milestones		[ { :meet => {:hours => 24}}, { :late => {:minutes => 15} } ]
	end
	factory :reschedule_clause, class: Clause do
		name					{ "Reschedule" }
		ruby_module				{ :Reschedule }
		relative_milestones		[ { :reschedule => {:hours => -4} } ]
	end

	factory :cancel_clause, class: Clause do
		name					{ "Cancel without penalty" }
		ruby_module				{ :Cancel }
		relative_milestones		[ { :cancel => {:hours => -24} } ]
	end

	factory :inspection_clause, class: Clause do
		name					{ "Inspect goods" }
		ruby_module				{ :Inspection }
		relative_milestones		[ { :inspect => {:hours => 1} } ]
	end

	factory :accept_goods_clause, class: Clause do
		name					{ "Accept Goods" }
		ruby_module				{ :Acceptance }
		relative_milestones		[ { :accept => {:minutes => 15} } ]
	end

	factory :close_clause, class: Clause do
		name					{ "Close Transaction" }
		ruby_module				{ :Close }
		relative_milestones		[ { :close => {:hours => 3} } ]
	end

	######################################################################
	#
	# Role 
	factory :role, class: Role do |role|
		name	{ "Buyer" }
	end

	######################################################################
	#
	# Contract
	factory :contract, class: Contract do |contract|

		name			{ "Craigslist Standard Purchase Agreement" }
		ruby_module		{ "::CRStandardPurchaseAgreementModule" }
		summary			{ "Default Craigslist purchase contract" }
		tags			{ [:craigslist, :default] }

	end

	######################################################################
	#
	# Xasset 
	factory :xasset, class: Xasset do |xasset|
		name { "Buyer Deposit" }
		asset_type { :deposit }
	end

	######################################################################
	#
	# Evidence 
	factory :evidence do |evidence|
		evidence_type	{ :location_verification }
		source			{ :system }
		description		{ :gps }
	end

	######################################################################
	#
	# Obligation 
	factory :obligation do |obligation|
		state			{ :active }
		milestones		[] 
	end

	######################################################################
	#
	# Valuable 
	factory :valuable do |valuable|
		description			{ "Rolex Watch" }
		more_description	{ "Authentic Rolex P55 paratrooper-wanabee in excellent condition" } 
	end

	######################################################################
	#
	# Party 
	factory :party do |party|
	end

	######################################################################
	#
	# Transaction 
	factory :transaction do |transaction|
		status	{ :open }
	end

	sequence :first_name do |n|
		"first#{n}"	
	end

	sequence :last_name do |n|
		"last#{n}"	
	end

	sequence :email do |n|
		"first.last#{n}@example.com"
	end


	sequence :clause do |n|
		"clause#{n}"
	end

end
