
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
	factory :user_without_account, class: User do |the_user|

		the_user.password				"foobar"
		the_user.password_confirmation	{ |n| n.password }	

		factory :user, class: User do |user|
			association	:account,		factory: :buyer_account
			user.first_name				"Seymore"
			user.last_name				"Butts"
			user.username				"sbutts@example.com"
		end

		factory :buyer_user, class: User do |user|
			association	:account,		factory: :buyer_account
			user.first_name				"Ms"
			user.last_name				"Buyer"
			user.username				"buyer@example.com"
		end

		factory :seller_user, class: User do |user|
			association	:account,		factory: :seller_account
			user.first_name				"Mr"
			user.last_name				"Seller"
			user.username				"seller@example.com"
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
	factory :seller_email_contact, class: EmailContact do |contact|
		contact.contact_data	"seller@example.com"
	end

	factory :buyer_email_contact, class: EmailContact do |contact|
		contact.contact_data	"buyer@example.com"
	end

	factory :seller_username_contact, class: UsernameContact do |contact|
		contact.contact_data	"seller@example.com"
	end

	factory :buyer_username_contact, class: UsernameContact do |contact|
		contact.contact_data	"buyer@example.com"
	end

	factory :seller_sms_contact, class: SMSContact do |contact|
		contact.contact_data	"4085551001"
	end

	factory :buyer_sms_contact, class: SMSContact do |contact|
		contact.contact_data	"4085551002"
	end

end

