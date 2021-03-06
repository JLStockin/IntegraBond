require 'spec_helper'
require 'active_support/time'

TEST_GOAL = Contracts::Bet::TestGoal
TEST_GOAL_FALSE = Contracts::Bet::TestGoalFalse
GOAL = Contracts::Bet::GoalTenderOffer
#GOAL_CHILDREN = [:GoalAcceptOffer, :GoalCancelOffer]
Contracts::Bet::GoalTenderOffer::EXPIRATION = :TestExpiration 
EXPIRATION_ARTIFACT = Contracts::Bet::TestTimeoutArtifact
Contracts::Bet::ContractBet::EXPIRATIONS = [:TestExpiration, :OfferExpiration, :BetExpiration]

Contracts::Bet::GoalTenderOffer::SELF_PROVISION = false # Don't let first Goal provision itself

RSpec.configure do |c|
#	c.fail_fast = true
end

describe "Goal class" do

	it "should have a set of class methods" do
		Goal.should respond_to :children
		Goal.should respond_to :favorite_child?
		Goal.should respond_to :stepchildren
		Goal.should respond_to :available_to
		Goal.should respond_to :valid_goal?
	end

	it "should be a valid Goal" do
		Goal.valid_goal?.should be_true
	end

end

describe "Goal instance" do

	before(:each) do
		@goal = TEST_GOAL.new
	end

	it "should permit injection of methods into statemachine" do
		Goal.state_machine.should respond_to :inject_provisioning
		Goal.state_machine.should respond_to :inject_disable
		Goal.state_machine.should respond_to :inject_undo
		Goal.state_machine.should respond_to :inject_expiration
	end
	it "should start out with state of :s_initial" do
		@goal.state_name.should be == :s_initial
	end

	it "can have an artifact" do
		@goal.should respond_to(:artifact)
	end

	it "can have an expiration" do
		@goal.should respond_to(:expiration)
	end

	it "should have a set of instance methods" do
		@goal.should respond_to :disable_stepchildren
		@goal.should respond_to :procreate
		@goal.should respond_to :active?
		@goal.should respond_to :execute
		@goal.should respond_to :reverse_execution
		@goal.should respond_to :on_expire
	end

	it "should respond to statemachine events" do
		@goal.should respond_to :start
		@goal.should respond_to :_start
		@goal.should respond_to :provision
		@goal.should respond_to :disable
		@goal.should respond_to :undo
		@goal.should respond_to :expire
	end

end

describe "Goal in active Tranzaction" do

	before(:each) do
		@tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet) 
		@tranz.start(true)
		@goal = @tranz.goals[0]
	end

	describe "asked to start" do

		it "start out in an intial state" do
			@goal.state_name.should be == :s_initial
		end

		it "should change state after starting" do
			@goal.start()
			@goal.state_name.should be == :s_provisioning
		end
		
	end

	it "should disable" do
		@goal.start()
		@goal.active?.should be_true
		@goal.disable()
		@goal.reload()
		@goal.active?.should be_false
	end

	it "should remember its state" do
		@goal.start()
		@goal.active?.should be_true
		@goal.disable()
		@goal.reload
		@goal.active?.should be_false
	end

	it "should be connected to the right Expiration" do
		@goal.start()
		@goal.expiration.should be == @tranz.model_instance(@goal.class.expiration)
	end

	describe "when it expires" do
		before(:each) do
			@goal.start()
			@expiration = @tranz.model_instance(@goal.class.expiration)
		end

		it "should produce the right Artifact (create_artifact_for)" do
			@artifact = @tranz.create_artifact_for(@expiration, @tranz.party1) 
			@artifact.should_not be_nil
			@artifact.instance_of?(EXPIRATION_ARTIFACT).should be_true
		end

		it "should disable Goal" do
			@goal.active?.should be_true
			@artifact = @tranz.create_artifact_for(@expiration, @tranz.party1) 
			@goal.reload
			@goal.active?.should be_false
		end
	end

	describe "when provisioned" do

		it "should no longer be active" do
			@goal.start()
			@goal.active?.should be_true
			artifact = @tranz.create_artifact_for(@goal, @tranz.party1) 
			artifact.should_not be_nil
			@goal.reload
			@goal.active?.should be_false
		end

		it "funds should be reserved" do
			account = @tranz.party1.contact.user.account
			account.available_funds.should be == Money.parse("$1000")	
			@goal.start()
			artifact = @tranz.create_artifact_for(@goal, @tranz.party1) 
			account.reload()
			account.available_funds.should be < Money.parse("$1000")	
		end

		it "should not raise an exception if execute returns true" do
			@goal.class.class_eval do
				def execute(artifact)
					return true 
				end
			end
			@goal.start()
			artifact = @tranz.build_artifact_for(@goal) 
			artifact.save!
			expect {@goal.provision(artifact)}.to_not raise_error
		end

		it "should not raise an exception if execute returns false" do
			@goal.class.class_eval do
				def execute(artifact)
					return false
				end
			end
			@goal.start()
			artifact = @tranz.build_artifact_for(@goal) 
			artifact.save!
			expect {@goal.provision(artifact)}.to_not raise_error
		end
	end

	describe "when provision!'d" do

		it "should not raise an exception if execute returns true" do
			@goal.class.class_eval do
				def execute(artifact)
					return true 
				end
			end
			@goal.start!()
			artifact = @tranz.build_artifact_for(@goal) 
			artifact.save!
			expect {@goal.provision!(artifact)}.to_not raise_error
		end

		it "should raise an exception if execute returns false" do
			@goal.class.class_eval do
				def execute(artifact)
					return false
				end
			end
			@goal.class.const_set("STUBBORN", false)
			@goal.start()
			artifact = @tranz.build_artifact_for(@goal) 
			artifact.save!
			expect {@goal.provision!(artifact)}.to raise_error
		end

		it "should not raise an exception even if execute returns false if goal is stubborn" do
			@goal.class.class_eval do
				def execute(artifact)
					return false
				end
			end
			@goal.class.const_set("STUBBORN", true)
			@goal.start()
			artifact = @tranz.build_artifact_for(@goal) 
			artifact.save!
			expect {@goal.provision!(artifact)}.to_not raise_error
		end

		it "(should cleanup after itself)" do
			@goal.class.class_eval do
				def execute(artifact)
					return true 
				end
			end
		end

	end

	describe "child Goals" do
		before(:each) do
			@goal.start()
			artifact = @tranz.create_artifact_for(@goal, @tranz.party1) 
			@goal.reload
		end
			
		it "should be created and active" do
			@goal.class.children().each do |sym|
				child = @tranz.model_instance(sym)
				child.should_not be_nil
				child.active?.should be_true
			end
		end

		it "should be disabled" do
			@goal.disable_stepchildren()
			@goal.class.stepchildren().each do |sym|
				child = @tranz.model_instance(sym)
				child.active?.should be_false
			end
		end

		it "should be cancelled when a Tranzaction is cancelled" do
			@goal.cancel_tranzaction
			@goal.class.children().each do |sym|
				child = @tranz.model_instance(sym)
				child.active?.should be_false
			end
			@goal.reload
			@goal.active?.should be_false
		end

	end

	it "should undo" do
		@goal.start()
		@goal.active?.should be_true

		p1 = @tranz.party1
		account = p1.contact.user.account
		account.available_funds.should be == Money.parse("$1000")	
		@tranz.create_artifact_for(@goal, @tranz.party1) 
		account.reload
		account.available_funds.should be < Money.parse("$1000")	
		@goal.reload
		@goal.active?.should be_false
		@goal.undo
		account.reload
		account.available_funds.should be == Money.parse("$1000")	
		@goal.active?.should be_false
	end

	it "should call subclassed Goal's execute() on provision event" do
		$executed = false
		def @goal.execute(artifact)
			$executed = true
			true
		end

		@goal.start()
		@tranz.create_artifact_for(@goal, @tranz.party1) 
		$executed.should be_true
	end

	it "should call reverse_execution() on undo event" do
		$reversed = false
		def @goal.reverse_execution()
			$reversed = true
			true
		end

		@goal.start()
		@tranz.create_artifact_for(@goal, @tranz.party1) 
		@goal.reload
		@goal.undo!()
		$reversed.should be_true
	end

	it "should call Goal subclass's on_expire() on the expire event" do

		# Override GoalTenderOffer#on_expire, since we can't control which
		# ActiveRecord proxy object is created for our Goal instance when
		# this callback gets called.

		$expired = false
		p = lambda do |artifact|
			$expired = true
		end
		Contracts::Bet::GoalTenderOffer.send( :define_method, :on_expire, p	)

		@goal.start()
		sleep(2)
		Expiration.sweep()
		$expired.should be_true
	end
end

describe "Goal (re: missing callbacks)" do
	before(:each) do
		@tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet) 
		class BogusGoal < Goal
		end
		@bogus = BogusGoal.new()
		@bogus.tranzaction = @tranz
		@bogus.save!
	end

	it "should complain if execute() isn't implemented in Goal subclass" do
		expect {
			@bogus.execute(nil)
		}.to raise_error
	end

	it "should complain if reverse_execution() isn't implemented in Goal subclass" do
		expect {
			@bogus.reverse_execution(nil)
		}.to raise_error
	end

	it "should complain if on_expire() isn't implemented in Goal subclass" do
		expect {
			@bogus.on_expire(nil)
		}.to raise_error
	end

end
