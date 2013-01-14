require 'spec_helper'
require 'active_support/time'

describe Goal do

	before(:each) do
		@goal = Contracts::Test::TestGoal.new()
		@goal.contract_id = 1 
		@goal.save!
	end

	it "should start out with state of :s_initial" do
		@goal.machine_state_name.should be == :s_initial
	end

	it "should have an artifact" do
		@contract.should respond_to(:artifact)
	end

	it "should have a set of instance methods" do
		@trans.goals[0].should respond_to :active?
		@trans.goals[0].should respond_to :deactivate
		@trans.goals[0].should respond_to :deactivate_stepchildren
		@trans.goals[0].should respond_to :deactivate_other
		@trans.goals[0].should respond_to :get_expiration
		@trans.goals[0].should respond_to :evaluate_expiration
		@trans.goals[0].should respond_to :execute
		@trans.goals[0].should respond_to :reverse_execution
		@trans.goals[0].should respond_to :procreate
		@trans.goals[0].should respond_to :expire


		@trans.goals[0].should respond_to :start
		@trans.goals[0].should respond_to :provision
		@trans.goals[0].should respond_to :undo
		@trans.goals[0].should respond_to :chron

	end

	it "should have a set of class methods" do
		@trans.goals[0].class.should respond_to :artifact
		@trans.goals[0].class.should respond_to :children
		@trans.goals[0].class.should respond_to :stepchildren
		@trans.goals[0].class.should respond_to :valid_goal?
		@trans.goals[0].class.should respond_to :provision
		@trans.goals[0].class.should respond_to :check_goals_for_expiration
	end
end

describe Goal do

	before(:each) do
		@trans = Contracts::Test::TestContract.create!()
		@trans.start
		Goal.provision( \
			TestHelper.goal_id,
			TestHelper.artifact_class,
			TestHelper.the_hash \
		)
	end

	it "should remember expires_at" do
		time = DateTime.now
		@trans.goals[0].expires_at = time
		@trans.goals[0].save!
		@trans.goals[0].reload
		@trans.goals[0].expires_at.to_i.should be == time.to_i
	end

	it "should activate" do
		time = DateTime.now()
		time_plus_1s = time.advance(seconds: 1)

		@trans.goals[0].activate(time_plus_1s)
		@trans.goals[0].expires_at.to_i.should be == time_plus_1s.to_i
	end

	it "should set_expiration with no args and throw error" do
		expect {@trans.goals[0].set_expiration()}.should raise_error
	end

	it "should have an active? that works" do
		time = DateTime.now()
		@trans.goals[0].activate(time.advance(seconds: -1))
		@trans.goals[0].active?.should be_false
	end

	it "should have an active? that works" do
		time = DateTime.now()
		@trans.goals[0].activate(time.advance(seconds: 1))
		@trans.goals[0].active?.should be_true
		@trans.goals[0].chron
		@trans.goals[0].active?.should be_true
		sleep(2)
		@trans.goals[0].chron
		@trans.goals[0].active?.should be_false
	end

	it "should have a 'check_goals_for_expiration' that works" do
		time = DateTime.now()
		@trans.goals[0].activate(time.advance(seconds: 1))
		@trans.goals[0].active?.should be_true
		@trans.goals[0].activate(time.advance(seconds: -1))
		Goal.check_goals_for_expiration
		@trans.goals[0].active?.should be_false
	end

	it "should have a deactivate that works" do
		time = DateTime.now()
		@trans.goals[0].activate(time.advance(seconds: 1))
		@trans.goals[0].active?.should be_true
		@trans.goals[0].deactivate()
		@trans.goals[0].active?.should be_false
	end

	it "should then remember its state" do
		@trans.goals[0].reload
		@trans.goals[0].machine_state_name.should be == :s_idle
	end

	it "should respond to a chron event" do
		@trans.goals[0].active?.should be_true
		sleep(3)
		@trans.goals[0].active?.should be_false
	end

	it "should expire" do
		@trans.goals[0].activate(DateTime.now.advance(seconds: 2))
		@trans.goals[0].active?.should be_true
		sleep(3)
		@trans.goals[0].active?.should be_false
	end

end
