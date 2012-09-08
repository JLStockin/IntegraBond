require 'spec_helper'
require 'active_support/time'

module IBContracts
module Test
end
end

class IBContracts::Test::TestGoal < Goal

	state_machine :machine_state, initial: :s_initial do
		event :advance do
			transition :s_ready => :s_state1
			transition :s_state1 => :s_state2
		end

		inject_expiration()
	end

	def provision(*params)
	end
end

describe Goal do
	before(:all) do
	end

	it "should create a new instance given valid attributes" do
		@goal = TestGoal.new() 
		@transaction = FactoryGirl.create(:test_transaction)
		@goal.transaction = @transaction 
		@goal.save!
		@transaction.goals << @goal
	end

	before(:each) do
		@goal = IBContracts::Test::GoalTest.new()
	end

	it "should start out with state of :s_initial" do
		@goal.machine_state_name.should be == :s_initial
	end

	it "should have a set of functions" do
		@goal.should respond_to :set_expiration
		@goal.should respond_to :active?
		@goal.should respond_to :deactivate

		@goal.should respond_to :start
		@goal.should respond_to :chron
		@goal.should respond_to :provision
	end

	it "should remember expires_at" do
		time = DateTime.now
		@goal.expires_at = time
		@goal.save!
		@goal.reload!
		g.expires_at.to_i.should be == time.to_i
	end

	it "should set_expiration with two args" do
		time = DateTime.now()
		time_plus_1s = time.advance(seconds: 1)

		@goal.set_expiration(time, {seconds: 1})
		@goal.expires_at.to_i.should be == time_plus_1s.to_i
	end

	it "should set_expiration with one arg" do
		time = DateTime.now()
		@goal.set_expiration(time)
		@goal.expires_at.to_i.should be == time.to_i
	end

	it "should set_expiration with no args and throw error" do
		expect {@goal.set_expiration()}.should raise_error
	end

	it "should have an active? that works" do
		time = DateTime.now()
		@goal.set_expiration(time.advance(seconds: -1))
		@goal.active?.should be_true
		@goal.chron
		@goal.active?.should be_false
	end

	it "should have an active? that works" do
		time = DateTime.now()
		@goal.set_expiration(time.advance(seconds: 1))
		@goal.active?.should be_true
		@goal.chron
		@goal.active?.should be_true
		sleep(2)
		@goal.chron
		@goal.active?.should be_false
	end

	it "should have a deactivate that works" do
		time = DateTime.now()
		@goal.set_expiration(time.advance(seconds: 1))
		@goal.active?.should be_true
		@goal.deactivate()
		@goal.active?.should be_false
	end

	it "should transition to :s_state1, then :s_state2" do
		@goal.advance
		@goal.machine_state_name.should be == :s_state1
		@goal.advance
		@goal.machine_state_name.should be == :s_state2
	end

	it "should then remember its state" do
		@goal.advance
		@goal.advance
		@goal.reload
		@goal.machine_state_name.should be == :s_state2
	end

	it "should expire" do
		@goal.set_expiration(DateTime.now.advance(seconds: 2))
		@goal.chron
		@goal.active?.should be_true
		sleep(3)
		@goal.chron
		@goal.active?.should be_false
	end

	it "should respond to a chron event" do
		@goal.active?.should be_true
		@goal.chron
		sleep(2)
		@goal.chron
		@goal.active?.should be_false
	end
end
