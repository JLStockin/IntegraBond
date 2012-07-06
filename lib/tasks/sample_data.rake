require 'faker'

namespace :db do
	desc "Fill database with sample data"
	task :populate => :environment do
		Rake::Task['db:reset'].invoke
		make_users
	end
end

def make_users

	admin =		User.build(			:first_name => "The",
									:last_name => "Admin",
									:email => "admin@gmail.com",
									:password => "foobar",
									:password_confirmation => "foobar"
								)
	admin.account =
		Account.build(				:available_funds => 0,
									:total_funds => 0
								)
	admin.account.user = admin
	admin.toggle!(:admin)
	admin.save!

	mike = User.build(				:first_name => "Michael",
									:last_name => "Durfee",
									:email => "mdurfee@gmail.com",
									:account_id => 2,
									:password => "foobar",
									:password_confirmation => "foobar"
								)
	mike.account =
		Account.build(				:available_funds => 0,
									:total_funds => 0
								)
	mike.account.user = mike 
	mike.save!

	98.times do |n|
		name  = Faker::Name.name
		name = name.split
		email = "example-#{n+2}@example.com"
		password  = "password"
		user = User.build(			:first_name => name[0],
									:last_name => name[1],
									:email => email,
									:password => password,
									:password_confirmation => password,
									:account_id => n + 2
								)
		user.account =
			Account.build(			:available_funds => 0,
									:total_funds => 0
								)
		user.account.user = user
		user.save!
	end
end

################################
#
# Simplest contract, no fees yet
#
################################
def make_contract(n)

	contract_attr = 
	{	# :name =>		"Craigslist purchase contract \##{n}",
		# :ruby_module =>	"IntegraBond::Contracts::Contract#{n}",	
		:summary =>		"Buy item(s) from Craigslist seller",
		:tags =>		"craigslist purchase cash"
	}
	clause_attr =
	{	:name =>		"Extend Offer",
		# :ruby_module => "IntegraBond::Contracts::Contract#{n}:ExtendOffer",
		:relative_t1 =>	1440,	# 24 hours to accept or expires
		:author =>		1
	}

	offer_clause = nil
	buyer = nil
	seller = nil
	goods = nil

	# Create 4 nearly identical contracts
	4.times do |n|
		# Create the contract without clauses (yet)
		contract_attr.merge!(:name =>		"Craigslist purchase contract \##{n}",
							:ruby_module =>	"IntegraBond::Contracts::Contract#{n}")
		contract = Contract.create!(contract_attr)

		offer_clause.merge!(:name =>		"Craigslist purchase contract \##{n}",
							:ruby_module =>	"IntegraBond::Contracts::Contract#{n}")

		if offer_clause.nil? then
			offer_clause = clause.create!(clause_attr)
		end

		if buyer.nil? then
			buyer = offer_clause.roles.create(	:name =>		"Buyer")
		end
		if seller.nil? then
			seller = offer_clause.roles.create(	:name =>		"Seller")
		end

		if goods.nil? then
			goods =
			offer_clause.xasset.create!(	:name =>				:goods,
											:type =>				:craigslist_item,
											:origin_role =>			2,
											:destination_role =>	2
										)
		end
		contract.add_clause(offer_clause)		

		offer_clause.involve(buyer)
		offer_clause.involve(seller)
		buyer.participate_in(offer_clause)
		seller.participate_in(offer_clause)
	end

end

