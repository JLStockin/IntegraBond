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
		user.account = Account.new(:name => "default")
		user.save!
		user
	end

	def create_test_transaction(class_name)
		trans = Object.module_eval(class_name).new
		user = FactoryGirl.build(:user)
		trans.author = user

		prior = Object.module_eval(class_name).new
		trans.prior_transaction = prior
		trans.role_of_origin = :buyer 
		trans.goals = [ show: {minutes: 20}, leave: {hours: 10} ]
		trans.machine_state = :unbound 
		trans.type = class_name 
		trans.fault = {seller: false, buyer: false}
		trans
	end


	def new_test_transaction(class_name)
		trans = Object.module_eval(class_name).new(@attr)
		trans.type = class_name 
		trans
	end

	def new_invalid_test_transaction(class_name)
		trans = Object.module_eval(class_name).new
		user = FactoryGirl.build(:user)
		trans.author = user

		prior = Object.module_eval(class_name).new
		trans.prior_transaction = prior
		trans.role_of_origin = :buyer 
		trans.goals = [ show: {minutes: 20}, leave: {hours: 10} ]
		trans.machine_state = :unbound 
		trans.type = class_name 
		trans.fault = {seller: false, buyer: false}
		trans
	end
	
	# Needed so contracts with no xassets don't break test for xassets
	def test_for_valid_xasset
		if Transaction.xassets.count > 0 then
			xasset = Transaction.xassets.keys[0]
			Transaction.has_xasset?(xasset)
		else
			true
		end
	end

	def test_for_invalid_xasset
		if Transaction.xassets.count > 0 then
			Transaction.has_xasset?(:dead_skunks)
		else
			false
		end
	end

end
