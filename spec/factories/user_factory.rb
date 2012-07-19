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

	factory :user_without_account, class: User do |user|

		user.first_name		FactoryGirl.generate(:first_name)
		user.last_name		FactoryGirl.generate(:last_name)
		user.email			FactoryGirl.generate(:email)

		user.password				"foobar"
		user.password_confirmation	"foobar"

		factory :user do |user|

			after(:build) do |user, context|
				attr = FactoryGirl.attributes_for(:account)
				user.build_account(attr)
			end

			after(:create) do |user, context|
				attr = FactoryGirl.attributes_for(:account)
				user.create_account(attr)
			end

		end

	end

	######################################################################
	#
	# Account, User
	factory :account do |account|
		name	"default"
	end

end
