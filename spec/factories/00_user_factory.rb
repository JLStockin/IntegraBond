
FactoryGirl.define do

	sequence :first_name do |n|
		"first#{n}"	
	end

	sequence :last_name do |n|
		"last#{n}"	
	end

	sequence :email do |n|
		"first#{n}.last#{n}@example.com"
	end

	######################################################################
	#
	# User 
	#
	factory :user_without_account, class: User do |the_user|

		the_user.password				"foobar"
		the_user.password_confirmation	{ |n| n.password }	

		factory :user, class: User do |user|
			association	:account,		factory: :buyer_account
			user.first_name				"Seymore"
			user.last_name				"Butts"
		end

		factory :buyer_user, class: User do |user|
			association	:account,		factory: :buyer_account
			user.first_name
			user.last_name
		end

		factory :seller_user, class: User do |user|
			association	:account,		factory: :seller_account
			user.first_name
			user.last_name
		end
	end

	######################################################################
	#
	# Account
	#
	factory :account, class: Account do |account|
		funds_cents			0
		hold_funds_cents	0
		funds_currency		"USD"

		factory :admin_account do |account|
			account.name "admin"
		end

		factory :buyer_account do |account|
			account.name "buyer"
		end

		factory :seller_account do |account|
			account.name "seller"
		end
	end

	######################################################################
	#
	# Contact 
	#
	factory :seller_email, class Contact do |contact|
		association :user,		:factory => :seller_user
		contact.contact_data	"user1@example.com"
	end

	factory :buyer_email, class Contact do |contact|
		association :user,		:factory => :buyer_user
		contact.contact_data	"user2@example.com"
	end

	factory :seller_phone, class Contact do |contact|
		association :user,		:factory => :seller_user
		contact.contact_data	"408-555-1001"
	end

	factory :buyer_phone, class Contact do |contact|
		association :user,		:factory => :buyer_user
		contact.contact_data	"408-555-1002"
	end

end

