require 'spec_helper'

# TODO: create macro that creates the contract namespace
module IBContracts
module Test
end
module Bad
end
end


# Class-level validations for Contracts (validations on superclass Contract)
#
describe Contract do

	describe " meta-class" do

		before(:each) do
			@contracts = ContractManager.contracts
			@contract = @contracts[0]
		end

		it "should have found contract(s)" do
			@contracts.should_not be_nil
			@contracts.count.should be > 0
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
			@trans.class.first_goals[0].should be == :TestGoal
		end
		
		it "should have a request_provisioning method" do
			@trans.should respond_to :request_provisioning
		end

		it "should have a model_instances method" do
			@trans.should respond_to :model_instances
		end

		it "should have a model_instance method" do
			@trans.should respond_to :model_instance
		end

		it "should have a expiration_for method" do
			@trans.should respond_to :expiration_for
		end

		it "should have a working expiration_for method" do
			goal = @trans.class.first_goals[0]
			@trans.expiration_for(goal).should_not be_nil
		end

		it "should have a working provision method" do
			@trans.model_instances(@trans.artifacts, :TestArtifact).should be_nil 
			Goal.provision(\
				TestHelper.goal_id,
				TestHelper.artifact_class,		
				TestHelper.the_hash\
			)
			@trans.model_instances(@trans.artifacts, :TestArtifact).count.should be > 0
		end

		it "should have an artifact with the right values" do
			Goal.provision(\
				TestHelper.goal_id,
				TestHelper.artifact_class,
				TestHelper.the_hash\
			)
			artifact = (@trans.model_instances(@trans.artifacts, :TestArtifact))[0]
			artifact.a.should be == "yes" 
			artifact.b.should be == "yes" 
			artifact.value_cents.should be == Money.parse("$100").cents
		end

		it "should have 3 Parties" do 
			Goal.provision(\
				TestHelper.goal_id,
				TestHelp.artifact_class,
				TestHelper.the_hash\
			)
			@trans.goals[0].advance
			@trans.parties.count.should be == 3
		end

		it "should have the right three parties" do
			Goal.provision(\
				TestHelper.goal_id,
				TestHelper.artifact_class,
				TestHelper.the_hash\
			)
			@trans.goals[0].advance
			@trans.model_instance(@trans.parties, :Party1).count.should be > 0
			@trans.model_instance(@trans.parties, :Party2).count.should be > 0
		end

		it "should have valuables" do
			@trans.should respond_to :valuables
		end

		it "should have valuables" do
			Goal.provision(\
				TestHelper.goal_id,
				TestHelper.artifact_class,
				TestHelper.the_hash\
			)
			@trans.goals[0].advance
			@trans.valuables.count.should be == 2

			@trans.valuables.each do |valuable|
				@trans.model_instance(\
					@trans.valuables,
					Object.const_to_symbol(valuable.class)\
				).count.should be > 0
			end
		end

	end

	describe "internal states" do
		before(:each) do
			@contract = IBContracts::Test::TestContract
			@trans	= @contract.create!()
			@trans.start()
			Goal.provision(\
				TestHelper.goal_id,
				TestHelper.artifact_class,
				TestHelper.the_hash\
			)
		end

		it "should have a :s_ready state" do
			@trans.goals[0].machine_state_name.should be == :s_create_objects
		end

		it "should be in the right state after an :advance" do
			@trans.goals[0].advance
			@trans.goals[0].machine_state_name.should be == :s_ready
			@trans.goals[0].advance()
			@trans.goals[0].machine_state_name.should be == :s_state1
		end

		it "should working activate(), deactivate(), active?() methods" do
			goal = (@trans.model_instance(@trans.goals, :TestGoal))[0]
			goal.activate(DateTime.now.advance(seconds: 2))
			goal.active?.should be_true
			goal.deactivate()
			goal.active?.should be_false
			goal.activate(DateTime.now.advance(seconds: 10))
			goal.active?.should be_true
		end
	end

end
