require 'spec_helper'

describe Transaction do
	before(:each) do
		@contract = FactoryGirl.create(:contract)
		@prior = FactoryGirl.create(:transaction)
		@origin = FactoryGirl.create(:user)
		@attr = FactoryGirl.attributes_for(:transaction)
		@obligation = FactoryGirl.create(:obligation)
	end

	it "should create a new instance given valid attributes" do
		@trans = Transaction.new(@attr)
		@trans.contract = @contract
		@trans.prior_transaction = @prior
		@trans.party_of_origin = @origin
		@trans.obligations << @obligation
		@trans.save!
	end

	it "should have a contract" do
		@trans = Transaction.new(@attr)
		@trans.should respond_to(:contract)
	end

	it "may have a prior transaction" do
		@trans = Transaction.new(@attr)
		@trans.should respond_to(:prior_transaction)
	end

	it "should have a party of origin" do
		@trans = Transaction.new(@attr)
		@trans.should respond_to(:party_of_origin)
	end

	it "should have obligations" do
		@trans = Transaction.new(@attr)
		@trans.should respond_to(:obligations)
	end

end
