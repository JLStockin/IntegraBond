require 'spec_helper'
require 'active_support/time'

class ArtifactFoo
	def to_event; self.class.to_s.underscore.to_sym; end
end

class GoalTest < Goal
	param_accessor :a, :b, :shutdown_time
	attr_accessor :transaction

	state_machine :machine_state, initial: :s_initial do
		event :advance do
			transition :s_initial => :s_state1
			transition :s_state1 => :s_state2
		end

		event :artifact_foo do
			transition all => :s_got_a_foo
		end

		event :chron do
			transition all - :s_expired => :s_expired,
				:if => lambda { |goal| goal.expires_at.to_i < DateTime.now.to_i }
		end
	end
end

class Transaction < ActiveRecord::Base
end

describe Goal do
	before(:all) do
		@party1 = FactoryGirl.build(:party1)
		@party2 = FactoryGirl.build(:party2)
	end

	it "should create a new instance given valid attributes" do
		@goal = GoalTest.new()
		@goal.transaction = Transaction.new()
		@goal.save!
	end

	before(:each) do
		@party1.user.account.set_funds(1000, 0)
		@party2.user.account.set_funds(1000, 0)
		@goal = GoalTest.new()
	end

	it "should start out with state of :s_initial" do
		@goal.machine_state_name.should be == :s_initial
	end

	it "should have a set of functions" do
		@goal.should respond_to :set_expiration
		@goal.should respond_to :active?
		@goal.should respond_to :deactivate
		@goal.should respond_to :send_event
	end

	it "should remember expires_at" do
		time = DateTime.now
		@goal.expires_at = time
		@goal.save!
		id = @goal.id
		g = Goal.find(id)
		g.expires_at.to_i.should be == time.to_i
	end

	it "should make set_expiration with two args should work" do
		time = DateTime.now()
		time_plus_1s = time.advance(seconds: 1)

		@goal.set_expiration(time, {seconds: 1})
		@goal.expires_at.to_i.should be == time_plus_1s.to_i
	end

	it "should make set_expiration with one arg should work" do
		time = DateTime.now()
		@goal.set_expiration(time)
		@goal.expires_at.to_i.should be == time.to_i
	end

	it "should make set_expiration with no args should throw error" do
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

	it "should have a working send_event" do
		@goal.send_event(ArtifactFoo.new)
		@goal.machine_state_name.should be == :s_got_a_foo
	end

	it "should be able to write and read params a, b in _data" do
		@goal.a = "a"
		@goal.b = "b"
		@goal.save!
		id = @goal.id
		g = Goal.find(id)
		g.a.should be == "a"
		g.b.should be == "b"
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
		id = @goal.id
		g = Goal.find(id)
		g.machine_state_name.should be == :s_state2
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
