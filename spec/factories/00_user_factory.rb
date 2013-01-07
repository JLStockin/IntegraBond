require 'contact'

ADMIN_EMAIL = "admin@example.com"

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

	sequence :phone do |n|
		"408-555-%04d" % n
	end

	sequence :username do |n|
		"first#{n}.last#{n}@example.com"
	end

	######################################################################
	#
	# User 
	#
	factory :basic_user, class: User do |user|

		user.password					"foobar"
		user.password_confirmation		{ |n| n.password }	

		factory :user_attributes, class: User do |user|
			user.first_name				"Seymour"
			user.last_name				"Butz"
			user.username				"sbutz@example.com"
		end

		factory :buyer_user, class: User do |user|
			user.first_name				"Ms"
			user.last_name				"Buyer"
			user.username				"buyer@example.com"
		end

		factory :seller_user, class: User do |user|
			user.first_name				"Mr"
			user.last_name				"Seller"
			user.username				"seller@example.com"
		end

		factory :admin_user, class: User do |user|
			user.first_name					"M"
			user.last_name					"Admin"
			user.username					ADMIN_EMAIL	
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
	# The seeded data already in the DB
	#
	factory :user1_email, class: EmailContact do |contact|
		contact.contact_data		"cschille@example.com"
	end

	factory :user1_sms, class: SMSContact do |contact|
		contact.contact_data		"4085551002"
	end

	factory :user1_username, class: UsernameContact do |contact|
		contact.contact_data		"cschille1@example.com"
	end

	factory :user2_email, class: EmailContact do |contact|
		contact.contact_data		"sinolean@example.com"
	end

	factory :user2_sms, class: SMSContact do |contact|
		contact.contact_data		"4085551003"
	end

	factory :user2_username, class: UsernameContact do |contact|
		contact.contact_data		"sinolean@example.com"
	end

	factory :admin_email, class: EmailContact do |contact|
		contact.contact_data		ADMIN_EMAIL	
		association :user,			factory: :admin_user
	end

	######################################################################
	#
	# User-less Contacts
	#

	factory :seller_email, class: EmailContact do |contact|
		contact.contact_data		"seller@example.com"
	end

	factory :buyer_email, class: EmailContact do |contact|
		contact.contact_data		"buyer@example.com"
	end

	factory :seller_username, class: UsernameContact do |contact|
		contact.contact_data		"seller@example.com"
	end

	factory :buyer_username, class: UsernameContact do |contact|
		contact.contact_data		"buyer@example.com"
	end

	factory :seller_sms, class: SMSContact do |contact|
		contact.contact_data		"4085551004"
	end

	factory :buyer_sms, class: SMSContact do |contact|
		contact.contact_data		"4085551005"
	end
end

