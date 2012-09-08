require 'spec_helper'

# TODO: create macro that creates the contract namespace
module IBContracts
module Test
end
module Bad
end
end

class IBContracts::Test::TestContract < Contract::Base

	VERSION = "0.1"
	CONTRACT_NAME = "Test Contract"
	SUMMARY = "This is a test"
	AUTHOR_EMAIL = "cschille@gmail.com" 

	FIRST_GOAL = :TestGoal

	DEFAULT_BOND = {:Party1 => Money.parse("$20"), :Party2 => Money.parse("$20")}

	TAGS = %W/test default/

	# In real life, this calls a controller and/or looks at other Artifacts.

	def request_provisioning(artifact_klass, goal_id, initial_params)
		hash = {}
		initial_params.each_key do |param|
			hash[param] = "yes" unless param == :value or param == :expire
		end
		hash[:value] = Money.parse("$100")
		hash[:expire] = initial_params[:expire] 
		TestHelper.stash_return_values(goal_id, hash)
	end
end

class IBContracts::Test::TestGoal < Goal

	EXPIRE = "DateTime.now.advance( seconds: 2 )"

	ARTIFACT = :TestArtifact

	state_machine :machine_state, initial: :s_initial do
		inject_provisioning(:s_initial, :s_ready)

		event :advance do
			transition :s_ready => :s_my_objects_created
			transition :s_my_objects_created => :s_state2
		end

		before_transition :s_ready => :s_my_objects_created do |goal, transition|

			user1 = User.find(3)
			party1 = goal.contract.class.namespaced_const(:Party1).new
			party1.user_id = user1.id
			party1.contract_id = goal.contract_id
			party1.save!

			user2 = User.find(4)
			party2 = goal.contract.class.namespaced_const(:Party2).new
			party2.user_id = user2.id
			party2.contract_id = goal.contract_id
			party2.save!

			valuable1 = IBContracts::Test::Valuable1.new( \
				contract_id: goal.contract_id,
				value: TestHelper.the_hash[:value],
				origin_id: party1.id, disposition_id: party1.id \
			)
			valuable1.contract_id = goal.contract_id
			valuable1.save!

			valuable2 = IBContracts::Test::Valuable2.new( \
				contract_id: goal.contract_id,
				value: TestHelper.the_hash[:value],
				origin_id: party2.id, disposition_id: party2.id \
			)
			valuable2.contract_id = goal.contract_id
			valuable2.save!

			true
		end

		inject_expiration(:s_my_objects_created)
	end

end

class IBContracts::Test::TestArtifact < Artifact 

	param_accessor :a, :b, :value_cents, :expire
	monetize :value_cents

	attr_accessible :a, :b, :value, :expire

	PARAMS = { a: :no, b: :no, value: Money.parse("$25") }
	
end

class IBContracts::Test::Valuable1 < Valuable
	attr_accessible :value
end

class IBContracts::Test::Valuable2 < Valuable
end

class IBContracts::Test::Party1 < Party
end

class IBContracts::Test::Party2 < Party
end

class TestHelper
	class << self
		attr_accessor :goal_id, :the_hash, :trans
	end
	def self.stash_return_values(goal_id, hash)
		self.goal_id = goal_id
		self.the_hash = hash
	end
end

# Class-level validations for Contracts (validations on superclass Contract)
#
describe Contract do

	describe " meta-class" do

		before(:each) do
			@contract = ContractManager.contracts[0]
		end

		it "should have found contract(s)" do
			@contract.should_not be_nil
		end

		it "returns true for valid_contract? with a valid contract" do
			@contract.valid_contract?.should be_true
		end

		it "error for valid_contract_type? with an invalid contract" do
			expect {IBContracts::Test::BadContract.valid_contract?()}.should raise_error 
		end
	end

	describe ": class methods" do

		ContractManager.contracts.each do |contract|

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
				@contract.should respond_to(:first_goal)
			end

			it "should set reasonable fees" do
				@contract.should respond_to(:fees)
				@contract.fees.should be == Contract::Base::FEES[:default]
			end

		end	

	end

end


describe "Transaction (Contract instance)" do

	describe "initial setup" do

		it "should create a valid contract" do
			@contract = IBContracts::Test::TestContract
			@trans	= @contract.create!()
		end

	end

	describe "start" do
		before(:each) do
			@contract = IBContracts::Test::TestContract
			@trans	= @contract.create!()
			@trans.start()
		end

		it "should have a working house() method" do
			@trans.should respond_to :house
		end

		it "should have house method that returns the right party" do
			@trans.valid_contract?.should be_true
			party_admin = @trans.parties.first
			party_admin.user.admin.should be_true
			@trans.house.should be == party_admin 
		end

		it "should have parties" do 
			@trans.should respond_to :parties
		end

		it "should have a first_goal" do
			@trans.class.should respond_to :first_goal
		end

		it "should have the right goal" do
			@trans.class.first_goal.should be == :TestGoal
		end
		
		it "should have a request_provisioning method" do
			@trans.should respond_to :request_provisioning
		end

		it "should have a model_instance method" do
			@trans.should respond_to :model_instance
		end

		it "should have a working provision method" do
			@trans.model_instance(@trans.artifacts, :TestArtifact).should be_nil 
			ContractManager.provision(TestHelper.goal_id, TestHelper.the_hash)
			@trans.model_instance(@trans.artifacts, :TestArtifact).should_not be_nil 
		end

		it "should have an artifact with the right values" do
			ContractManager.provision(TestHelper.goal_id, TestHelper.the_hash)
			artifact = @trans.model_instance(@trans.artifacts, :TestArtifact)
			artifact.a.should be == "yes" 
			artifact.b.should be == "yes" 
			artifact.value_cents.should be == Money.parse("$100").cents
		end

		it "should have 3 Parties" do 
			ContractManager.provision(TestHelper.goal_id, TestHelper.the_hash)
			@trans.goals[0].advance
			@trans.parties.count.should be == 3
		end

		it "should have the right three parties" do
			ContractManager.provision(TestHelper.goal_id, TestHelper.the_hash)
			@trans.goals[0].advance
			@trans.model_instance(@trans.parties, :Party1).should_not be_nil
			@trans.model_instance(@trans.parties, :Party2).should_not be_nil
		end

		it "should have valuables" do
			@trans.should respond_to :valuables
		end

		it "should have valuables" do
			ContractManager.provision(TestHelper.goal_id, TestHelper.the_hash)
			@trans.goals[0].advance
			@trans.valuables.count.should be == 2

			@trans.valuables.each do |valuable|
				@trans.model_instance(\
					@trans.valuables,
					Object.const_to_symbol(valuable.class)\
				).should_not be_nil 
			end
		end

	end

	describe "internal states" do
		before(:each) do
			@contract = IBContracts::Test::TestContract
			@trans	= @contract.create!()
			@trans.start()
			ContractManager.provision(TestHelper.goal_id, TestHelper.the_hash)
		end

		it "should have a :s_ready state" do
			@trans.goals[0].machine_state_name.should be == :s_ready
		end

		it "should be in the right state after an :advance" do
			@trans.goals[0].advance
			@trans.goals[0].machine_state_name.should be == :s_my_objects_created
			@trans.goals[0].advance()
			@trans.goals[0].machine_state_name.should be == :s_state2
		end

		it "should working activate(), deactivate(), active?() methods" do
			goal = @trans.model_instance(@trans.goals, :TestGoal)
			goal.activate(DateTime.now.advance(seconds: 2))
			goal.active?.should be_true
			goal.deactivate()
			goal.active?.should be_false
			goal.activate(DateTime.now.advance(seconds: 10))
			goal.active?.should be_true
		end
	end

end
