
FactoryGirl.define do

	sequence :first_name do |n|
		"first#{n}"	
	end

	sequence :last_name do |n|
		"last#{n}"	
	end

	sequence :email do |n|
		"first.last#{n}@example.com"
	end

	######################################################################
	#
	# User 
	#
	factory :user_without_account, class: User do |the_user|

		the_user.password				"foobar"
		the_user.password_confirmation	"foobar"
		the_user.first_name				FactoryGirl.generate(:first_name)
		the_user.last_name				FactoryGirl.generate(:last_name)
		the_user.email					FactoryGirl.generate(:email)

		factory :user do |user|
			association :account
		end

		factory :buyer_user, class: User do |user|
			association	:account, factory: :buyer_account
		end

		factory :seller_user, class: User do |user|
			association :account, factory: :seller_account
		end

	end


	######################################################################
	#
	# Account
	#
	factory :account, class: Account do |account|
		account.name	"default"

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
end

