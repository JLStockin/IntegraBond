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
									:email => "admin@example.com",
									:password => "foobar",
									:password_confirmation => "foobar"
								)
	admin.build_account
	admin.account.user = admin
	admin.toggle!(:admin)
	admin.save!

	mike = User.new(				:first_name => "Michael",
									:last_name => "Durfee",
									:email => "mdurfee@example.com",
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

end

