require 'spec_helper'

describe Obligation do
	before(:each) do
		@attr = FactoryGirl.attributes_for(:obligation)
	end

	it "should create a new instance given valid attributes" do
		@obligation = Obligation.create!(@attr) 
	end

	it "should have a transaction" do
		@trans = Obligation.new(@attr)
		@trans.should respond_to(:transaction)
	end

	it "should have a clause" do
		@trans = Obligation.new(@attr)
		@trans.should respond_to(:clause)
	end

	it "should have evidence" do
		@trans = Obligation.new(@attr)
		@trans.should respond_to(:evidences)
	end

	it "should have valuables" do
		@trans = Obligation.new(@attr)
		@trans.should respond_to(:valuables)
	end

	it "should have parties" do
		@trans = Obligation.new(@attr)
		@trans.should respond_to(:parties)
	end

end
