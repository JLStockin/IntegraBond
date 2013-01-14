require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
	# Loading more in this block will cause your tests to run faster. However,
	# if you change any configuration or code from libraries loaded here, you'll
	# need to restart spork for it take effect.

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


  # This code will be run each time you run your specs.
	RSpec.configure do |config|

		# ActiveRecord::Base.logger = Logger.new(STDOUT)

		include FactoryGirl::Syntax::Methods

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

		#
		# Contract Helpers
		#

		def create_admin_user()
			# Creating the EmailContact also constructs the Admin User 
			FactoryGirl.create(:admin_email)
			u = User.where{username == "admin@example.com"}.first
			u.admin = true
			u.save(validate: false)
		end

		def prepare_test_tranzaction()
			user1 = FactoryGirl.create(:seller_user)
			contact = FactoryGirl.build(:seller_email)
			user1.contacts << contact

			user2 = FactoryGirl.create(:buyer_user)
			contact = FactoryGirl.build(:buyer_email)
			user2.contacts << contact

			klass = Contracts::Bet::ContractBet
			tranz = Contract.create_tranzaction(klass, user1)
			tranz
		end

		def update_test_tranzaction(tranz)
			user1 = User.find_by_username(FactoryGirl.attributes_for(:seller_user)[:username]) 
			params = {
				:contracts_bet_party1_bet => {:value => Money.parse("33.00")},
				:contracts_bet_party1_fees => {:value => Money.parse("0.99")},
				:contracts_bet_party2_bet => {:value => Money.parse("33.00")},
				:contracts_bet_party2_fees => {:value => Money.parse("0.99")},
				:contracts_bet_terms_artifact => {:text => "yada yada"},
				:contracts_bet_offer_expiration => {:offset => "2", :offset_units_index => "2"},
				:contracts_bet_bet_expiration => {:offset =>"2", :offset_units_index => "2"},
				tranz.party2.ugly_prefix => {
					:contact_strategy => Contact::CONTACT_METHODS[2],
					:find_type_index => "1",
					:associate_id => user1.id 
				}
			}

			tranz.update_attributes(params)
			tranz.party2.update_attributes(params)
			params
		end

		module Contracts
			module Test; end
		end
	
		class Contracts::Test::TestContract < Contract

			assoc_accessor(:TestArtifact)

			VERSION = "0.1"
			VALUABLES = [:Valuable1, :Valuable2]
			AUTHOR_EMAIL = "cschille@gmail.com"
			TAGS = %W/test default/
			EXPIRATIONS = [] 
			CHILDREN = [:TestGoal] 
			ARTIFACT = [] 
			PARTY_ROSTER = [:Party1]
			WIZARD_STEPS = []
			CONTRACT_NAME = "Test Contract"
			FORWARD_TRANSITIONS = []
			REVERSE_TRANSITIONS = []
			DEPENDENCIES = []
			SUMMARY = "This is a test"
	

		end

		class Contracts::Test::TestGoal < Goal

			EXPIRE = "DateTime.now.advance( seconds: 2 )"
			CHRON_PERIOD_SECONDS = 10
			CHILDREN = []
	
			state_machine :machine_state, initial: :s_initial do
				inject_provisioning()
				inject_expiration()
			end
	
			def procreate(artifact, params)
				user1 = User.find(3)
				party1 = self.class.namespaced_const(:Party1).new
				party1.user_id = user1.id
				party1.contract_id = self.contract_id
				party1.save!
	
				user2 = User.find(4)
				party2 = self.class.namespaced_const(:Party2).new
				party2.user_id = user2.id
				party2.contract_id = self.contract_id
				party2.save!
	
				valuable1 = Contracts::Test::Valuable1.new( \
					contract_id: self.contract_id,
					value: TestHelper.the_hash[:value],
					origin_id: party1.id, disposition_id: party1.id \
				)
				valuable1.contract_id = self.contract_id
				valuable1.save!
	
				valuable2 = Contracts::Test::Valuable2.new( \
					contract_id: self.contract_id,
					value: TestHelper.the_hash[:value],
					origin_id: party2.id, disposition_id: party2.id \
				)
				valuable2.contract_id = self.contract_id
				valuable2.save!
	
				super()
	
				true
			end
		
		end
	
		class Contracts::Test::TestArtifact < ProvisionableArtifact 
	
			A_CONSTANT = true
			IMMUTABLE = false 
			PARAMS = { a: :no, b: "hello", c: 12, value: Money.parse("$11") }
		
		end
	
		class Contracts::Test::Valuable1 < Valuable
			attr_accessible :value
		end
	
		class Contracts::Test::Valuable2 < Valuable; end
	
		class Contracts::Test::Party1 < Party; end
	
		class Contracts::Test::Party2 < Party; end
	
		class Contracts::Test::Friend < ActiveRecord::Base; end

		class TestHelper
			class << self
				attr_accessor :goal_id, :artifact_class, :the_hash
			end
			def self.stash_return_values(goal_id, klass, hash)
				self.goal_id = goal_id
				self.artifact_class = klass
				self.the_hash = hash
			end
		end
	end
end

Spork.each_run do
	load "app/models/contract.rb"
	load "app/models/expiration.rb"
	load "spec/models/contract_spec.rb"

end # Spork.each_run
