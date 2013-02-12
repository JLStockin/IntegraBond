require 'rubygems'
require 'spork'
require 'money'

#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

INITIAL_BALANCE = Money.parse("$1000")
VALUABLE_VALUE = Money.parse("$100")

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

		def create_user(factory_sym)
			user = FactoryGirl.create(factory_sym)
			user.account.deposit(INITIAL_BALANCE, "$0")
			user.account.save!
			user_prefix = factory_sym.to_s.split('_')[0] 
			user.contacts << FactoryGirl.build("#{user_prefix}_email".to_sym)
			user.contacts << FactoryGirl.build("#{user_prefix}_sms".to_sym)
			user
		end

		def create_admin_user()
			factory_sym = :admin_user
			user = create_user(factory_sym)
			user.admin = true
			user.save!
			user_prefix = factory_sym.to_s.split('_')[0] 
			user.contacts << FactoryGirl.build("#{user_prefix}_email".to_sym)
			user
		end

		def prepare_test_tranzaction(klass)
			create_admin_user()
			user1 = create_user(:seller_user)
			user2 = create_user(:buyer_user)

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
				tranz.party2.class.ugly_prefix => {
					:contact_strategy => Contact::CONTACT_METHODS[2],
					:find_type_index => "2",
					:associate_id => user1.id.to_s
				},
				:contact => { :contact_data => "joe.blow@example.com" }
			}

			tranz.update_attributes(params)
			tranz.party2.update_attributes(params)
			params
		end

		def resolve_party(tranz, party_sym)
			user = User.find_by_username(FactoryGirl.attributes_for(:buyer_user)[:username]) 
			party = tranz.model_instance(party_sym)
			party.contact = user.contacts[0]
			party.save!
			party
		end

		class Contracts::Bet::TestContract < Contract

			assoc_accessor(:TestArtifact)
			assoc_accessor(:PParty1)
			assoc_accessor(:PParty2)

			VERSION = "0.1"
			VALUABLES = [:Valuable1, :Valuable2]
			AUTHOR_EMAIL = "cschille@gmail.com"
			TAGS = %W/test default/
			EXPIRATIONS = [ \
				:OfferExpiration,
				:BetExpiration\
			]
			CHILDREN = [:TestGoal] 
			ARTIFACT = nil 
			PARTY_ROSTER = [:PParty1, :PParty2]
			WIZARD_STEPS = []
			CONTRACT_NAME = "Test Contract"
			FORWARD_TRANSITIONS = []
			REVERSE_TRANSITIONS = []
			DEPENDENCIES = []
			SUMMARY = "This is a test"
	

		end

		class Contracts::Bet::TestGoal < Goal

			ARTIFACT = :OfferPresentedArtifact 
			EXPIRATION = :TestExpiration
			CHILDREN = [:GoalAcceptOffer, :GoalCancelOffer]
			FAVORITE_CHILD = true
			STEPCHILDREN = []
			AVAILABLE_TO = [:PParty1]
			DESCRIPTION = "Present offer"
			SELF_PROVISION = false 

			def execute(artifact)
			end

			def reverse_execution()
			end
	
			def on_expire(artifact)
			end
		end

		class Contracts::Bet::TestExpiration < Expiration
			DEFAULT_OFFSET = 1 
			DEFAULT_OFFSET_UNITS = :seconds
			BASIS_TYPE = :TermsArtifact
			ARTIFACT = :TestTimeoutArtifact
		end

		class Contracts::Bet::TestTimeoutArtifact < ExpiringArtifact
		end

		class Contracts::Bet::TestArtifact < ProvisionableArtifact 
	
			A_CONSTANT = true
			IMMUTABLE = false 
			PARAMS = { a: :no, b: "hello", c: 12, value: Money.parse("$11") }
		
		end
	
		class Contracts::Bet::Valuable1 < Valuable
			VALUE = Money.parse("$11")
			OWNER = :PParty1
			ASSET = false
		end
	
		class Contracts::Bet::Valuable2 < Valuable
			VALUE = Money.parse("$11")
			OWNER = :PParty2
			ASSET = true 
		end
	
		class Contracts::Bet::PParty1 < Party
		end
	
		class Contracts::Bet::PParty2 < Party
		end
	
		class Contracts::Bet::Friend < ActiveRecord::Base
		end
	end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end # Spork.each_run
