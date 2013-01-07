require 'spec_helper'

# TODO: create macro that creates the contract namespace
module Contracts
module Test
end
module Bad
end
end

CONTRACT_LIST = [Contracts::Bet::ContractBet]

# Class-level validations for Contracts (validations on superclass Contract)
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
	[params, tranz]
end

describe Contract do

	describe " meta-class" do

		before(:each) do
			@contracts = CONTRACT_LIST 
			@contract = @contracts[0]
		end

		it "should have found contract(s)" do
			@contracts.should_not be_nil
			@contracts.count.should be > 0
		end

		it "returns true for valid_contract? with a valid contract" do
			@contract.valid_contract?.should be_true
		end

		it "should error for valid_contract_type? with an invalid contract" do
			expect {Contracts::Test::BadContract.valid_contract?()}.should raise_error 
		end
	end

	describe ": class methods" do

		CONTRACT_LIST.each do |contract|

			before(:each) do
				@contract = contract
			end

			it "should have a name" do
				@contract.should respond_to(:name)
				@contract.name.should_not be_nil
			end

			it "should have a summary" do
				@contract.should respond_to(:summary)
			end

			it "should have an a valid email address for author" do
				@contract.should respond_to(:author)
			end

			it "should have tags" do
				@contract.should respond_to(:tags)
			end

			it "should be able to locate a valid tag" do
				@contract.contains_tag?(:default).should_not be_nil
			end

			it "should be unable to locate an invalid tag" do
				@contract.contains_tag?(:bunga).should be_false
			end

			it "should have a first goal" do
				@contract.should respond_to(:children)
			end

			it "should support an Artifact (on the Contract)" do
				@contract.should respond_to(:artifact)
			end

			it "should have an author email address" do
				@contract.should respond_to(:author_email)
			end

			it "should include party_roster" do
				@contract.should respond_to(:party_roster)
			end

			it "should have all the necessary constants" do
				@contract.valid_contract?.should be_true
			end

		end	

	end

	it "should create a Tranzaction" do
		create_admin_user()
		klass = Contracts::Bet::ContractBet
		user1 = FactoryGirl.create(:seller_user)
		tranz	= Contract.create_tranzaction(klass, user1)
	end

end

describe "Tranzaction [sic]" do

	before(:each) do
		create_admin_user()	
		klass = Contracts::Bet::ContractBet
		@user1 = FactoryGirl.create(:seller_user)
		contact = FactoryGirl.build(:seller_email)
		@user1.contacts << contact
		contact = FactoryGirl.build(:seller_sms)
		@user1.contacts << contact
		@tranz = Contract.create_tranzaction(klass, @user1) 
	end

	describe "methods" do

		it "should include a working title() method" do
			@tranz.should respond_to :title
			@tranz.title.should_not be_nil
		end

		it "should include valuables" do
			@tranz.should respond_to(:valuables)
		end

		it "should include Expirations" do
			@tranz.should respond_to(:self_expirations)
			@tranz.should respond_to(:goal_expirations)
		end

		it "should include an originator" do
			@tranz.should respond_to(:originator)
		end

		it "should include a start() method" do
			@tranz.should respond_to :start
		end

		it "should include a goal" do
			@tranz.class.children[0].should be == :GoalTenderOffer
		end
		
		it "should include a model_instances method" do
			@tranz.should respond_to :model_instances
		end

		it "should include a model_instance method" do
			@tranz.should respond_to :model_instance
		end

		it "should include a latest_model_instance method" do
			@tranz.should respond_to :latest_model_instance
		end

		it "should include a request_provision method" do
			@tranz.should respond_to :request_provision
		end

		it "should include a expiration_for method" do
			@tranz.should respond_to :request_expiration
		end

	end

	it "should have an admin as party to the tranzaction" do
		@tranz.seed_tranzaction()
		@tranz.should respond_to :house
		@tranz.house.should_not be_nil
		party_admin = @tranz.parties.where{type == "AdminParty"}.first
		party_admin.contact.user.admin.should be_true
		@tranz.house().should be == party_admin 
	end

	describe "should synthesize association accessors" do
		
		it "like party1" do
			@tranz.should respond_to(:party1)
			@tranz.party1.should == @tranz.model_instance(:Party1)
		end

		it "like party2" do
			@tranz.should respond_to(:party2)
			@tranz.party2.should == @tranz.model_instance(:Party2)
		end

	end

	describe "model_instances" do
		it "should return multiple instances" do
			user1 = @tranz.model_instances(:Party1)[0].contact.user()
			extra_party = Contracts::Bet::Party1.new(
				contact_id: user1.contacts.first.id,
				tranzaction_id: @tranz.id
			)
			extra_party.save!

			_id = user1.id
			@tranz.model_instances(:Party1).first.should be == Party.first
puts "++++++++++++++> Party.all = #{Party.all}"
			@tranz.model_instances(:Party1).count.should be == 2
		end
	end

	describe "model_instance" do
		it "should return a single instance" do
			@tranz.model_instances(:Party1).count.should be == 1 
			@tranz.model_instances(:Party1).first.should be\
				== Party.where{parties.type == :Party1.to_s}
		end
		it "should fail with more than one matching instance" do
			expect {@tranz.model_instance(:Party)}.should raise_error 
		end
	end

	describe "first party" do
		before(:each) do
			@party1 = @tranz.parties.where{parties.type == Contracts::Bet::Party1.to_s}.first
		end

		it "should exist" do
			@party1.should_not be_nil
		end

		it "should have a contact of the right type" do
			@party1.contact.should_not be_nil
			@party1.contact.instance_of?(EmailContact).should be_true
		end
	end

	describe "terms" do
		it "should have been created" do
			@tranz.artifacts.first.should_not be_nil
			@tranz.artifacts.first.class.should be == Contracts::Bet::TermsArtifact
		end
	end

	describe "offer expiration" do
		it "should have been created" do
			@exp = @tranz.self_expirations.where{type \
				== Contracts::Bet::OfferExpiration.to_s}.first
			@exp.should_not be_nil
		end
	end

	describe "bet expiration" do
		it "should have been created" do
			@exp = @tranz.self_expirations.where{type \
				== Contracts::Bet::BetExpiration.to_s}.first
			@exp.should_not be_nil
		end
	end

	describe "other party not found expiration" do
		it "should have created an expiration for finding other party" do
			@exp = @tranz.self_expirations.where{type \
				== Contracts::Bet::OtherPartyNotFoundExpiration.to_s}.first
			@exp.should_not be_nil
		end
	end

	describe "second party" do
		it "should have been created" do
			party2 = @tranz.parties.where{type == Contracts::Bet::Party2.to_s}
			party2.should_not be_nil
		end
	end
		
	describe "party contact info" do
		describe "for first party" do
			it "should be user's first contact" do
				party1 = @tranz.parties.where{type == Contracts::Bet::Party1.to_s}.first
				party1.should_not be_nil
				party1.contact.should_not be_nil
				party1.contact.id.should be \
					== party1.contact.user.contacts.first.id
			end
		end
		describe "for second party" do
			it "should be an EmailContact" do
				party2 = @tranz.parties.where{type == Contracts::Bet::Party2.to_s}.first 
				party2.should_not be_nil
				party2.contact.should_not be_nil
				party2.contact.class.should be == EmailContact
			end
		end
	end

	describe "valuables" do
		it "should have updated party1's bet" do
			@tranz.model_instance(Contracts::Bet::Party1Bet).should_not be_nil
		end

		it "should have updated party2's bet" do
			@tranz.model_instance(Contracts::Bet::Party2Bet).should_not be_nil
		end

		it "should have created party1's fees" do
			@tranz.model_instance(Contracts::Bet::Party1Fees).should_not be_nil
		end

		it "should have created party2's fees" do
			@tranz.model_instance(Contracts::Bet::Party2Fees).should_not be_nil
		end
	end

	describe "provision/update" do

		before(:each) do
			@params = {
				:contracts_bet_party1_bet => {:value => Money.parse("33.00")},
				:contracts_bet_party1_fees => {:value => Money.parse("0.99")},
				:contracts_bet_party2_bet => {:value => Money.parse("33.00")},
				:contracts_bet_party2_fees => {:value => Money.parse("0.99")},
				:contracts_bet_terms_artifact => {:text => "yada yada"},
				:contracts_bet_offer_expiration => {:offset => "2", :offset_units_index => "2"},
				:contracts_bet_bet_expiration => {:offset =>"2", :offset_units_index => "2"},
			}
			@tranz.update_attributes(@params)
		end

		it "should have updated party1's bet" do
			@tranz.party1_bet.value.should be \
				== Money.parse(@params[:contracts_bet_party1_bet][:value])
		end

		it "should have updated party2's bet" do
			@tranz.party2_bet.value.should be \
				== Money.parse(@params[:contracts_bet_party1_bet][:value])
		end

		it "should have created party1's fees" do
			@tranz.party1_fees.value.should be == Money.parse("0.99")
		end

		it "should have created party2's fees" do
			@tranz.party2_fees.value.should be == Money.parse("0.99")
		end

		it "should have updated the artifact's text" do
			@tranz.terms_artifact.text.should be == @params[:contracts_bet_terms_artifact][:text]
		end

		it "should have updated the offer expiration" do
			@tranz.offer_expiration.offset.should be \
				== @params[:contracts_bet_offer_expiration][:offset].to_i
			@tranz.offer_expiration.offset_units_index.should be \
				== @params[:contracts_bet_offer_expiration][:offset_units_index].to_i
		end

		it "should have updated the bet expiration" do
			@tranz.bet_expiration.offset.should be \
				== @params[:contracts_bet_bet_expiration][:offset].to_i
			@tranz.bet_expiration.offset_units_index.should be \
				== @params[:contracts_bet_bet_expiration][:offset_units_index].to_i
		end

		it "should bind expirations to goals"

		describe "identify party2" do
			before(:each) do
				@params[@tranz.party2.ugly_prefix()] = {
					:contact_strategy => "find",
					:find_type_index => "2"
				}
				@params[:contact] = {
					:contact_data => "user2@example.com"
				}
				@tranz.party2.update_attributes(@params)
			end

			it "should have the correct contact strategy" do
				@tranz.party2.contact_strategy.should be \
					== @params[@tranz.party2.ugly_prefix()][:contact_strategy]
			end

			it "should have correct find type" do
				@tranz.party2.find_type_index.should be \
					== @params[@tranz.party2.ugly_prefix()][:find_type_index].to_i
			end

		end

		before(:each) do
			@params[@tranz.party2.ugly_prefix()] = {
				:contact_strategy => "invite",
				:find_type_index => "1"
			}
			@params[:contact] = {
				:contact_data => "joejoe@example.com"
			}
			@tranz.party2.update_attributes(@params)
		end

		it "should invite party2"

		describe "use associate for party2" do
			before(:each) do
				@params[@tranz.party2.ugly_prefix()] = {
					:contact_strategy => Contact::CONTACT_METHODS[2],
					:find_type_index => "1",
					:associate_id => @tranz.party1.id 
				}
				@params[:contact] = {
					:contact_data => "user2@example.com"
				}
				@tranz.party2.update_attributes(@params)
			end

			it "should have an associate with correct ID" do
				@tranz.party2.associate_id.should be \
					== @tranz.party2.get_associate_contact(@tranz.party1.contact.user, @params).id
			end
		end

		describe "publish for party2" do
			before(:each) do
				@params[@tranz.party2.ugly_prefix()] = {
					:contact_strategy => Contact::CONTACT_METHODS[3]
				}
				@tranz.party2.update_attributes(@params)
			end
			it "should have the correct contact strategy" do
				@tranz.party2.contact_strategy.should be \
					== @params[@tranz.party2.ugly_prefix()][:contact_strategy]
			end
		end

	end

	describe "needs help to create" do
		before(:each) do
			tuple = prepare_test_tranzaction()
			@params = tuple[0]
			@tranz = tuple[1]
			@tranz.start()
		end

		it "artifacts"

		it "parties"

		it "valuables"

		it "expirations"

	end

	describe "start" do

		before(:each) do
			tuple = prepare_test_tranzaction()
			@params = tuple[0]
			@tranz = tuple[1]
			@tranz.start()
		end

		it "should have created the first goal" do
			goal = @tranz.goals.first()
			goal.should_not be_nil
		end

		it "should have an artifact with the right values" do
			@tranz.artifacts.count.should be > 0
		end

	end

	describe "management" do

		it "should push updates to parties"

		it "should flash notices to parties"

		it "should give all the active goals for a user (tranzaction_goals)"

		it "should reverse a completed goals (reverse_completed_goals)"

		it "should disable a active goals (disable_active_goals)"

		it "should fetch the active goals for a party (active_goals)"

		it "should tell us if active (active?)"

		it "should tell us the status (status_object)"

		it "should tell us the next step to advance (current_success_goal)"

		it "should tell us which belong to a user (tranzactions_for)"

		it "give all the active goals for a user (tranzaction_goals)"
	end

end
