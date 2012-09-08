# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'factory_girl_rails'
require 'money'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|

	# ## Mock Framework
	#
	# If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
	#
	# config.mock_with :mocha
	# config.mock_with :flexmock
	# config.mock_with :rr

	# Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
	config.fixture_path = "#{::Rails.root}/spec/fixtures"

	# If you're not using ActiveRecord, or you'd prefer not to run each of your
	# examples within a transaction, remove the following line or assign false
	# instead of true.
	config.use_transactional_fixtures = true

	# If true, the base class of anonymous controllers will be inferred
	# automatically. This will be the default behavior in future versions of
	# rspec-rails.
	config.infer_base_class_for_anonymous_controllers = false

	def test_sign_in(user)
		controller.sign_in(user)
	end

	def integration_sign_in(user)
		visit signin_path
		fill_in :email,		:with => user.email
		fill_in :password,	:with => user.password
		click_button
	end

	def create_test_user
		user = User.new(FactoryGirl.attributes_for(:user))
		user.password = "foobar"
		user.password_confirmation = "foobar"
		user.account = Account.create(:name => "default")
		user.save!
		user
	end

	def new_test_transaction(contract, attributes=nil)
		trans = (attributes.nil?) ? contract.new : contract.new(attributes)
		trans.save!
		admin = trans.parties[0]

		party1 = trans.parties.create!(:user_id => User.find(3).id)
		party2 = trans.parties.create!(:user_id => User.find(4).id)
		trans.origin = party1

		valuable = trans.valuables.create!( \
			:origin_id => party1.id,
			:disposition_id => party1.id \
		)
		trans
	end

end
