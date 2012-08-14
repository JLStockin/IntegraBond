require 'spec_helper'

#
# Class-level validations for contracts (validations on superclass Transaction)
#
describe IBContracts::CLPurchase do

	before(:each) do
		@buyer = FactoryGirl.create(:buyer_user)
		@seller = FactoryGirl.create(:seller_user)

		@trans		=			Transaction.new
		@trans.type =			"CLPurchase"
		@trans.role_of_origin =	:seller
		@trans.milestones =		[ expire: {hours: 24}, meet: {hours: 6}, late: {minutes: 15} ]
		@trans.machine_state =	:s_binding
		@trans.fault =			[ buyer: false, seller: false ]
	end

	describe "milestone defaults are used correctly" do

	end

	describe "test the first state as the buyer" do
		before(:each) { @trans.role_of_origin = :buyer }

		it "should not bind any money" do
			pending
		end

		it "should be possible to save the listing" do
			pending
		end

		it "should be possible to delete the listing" do
			pending
		end

		it "should bind the buyer's funds and move to the second state"
			pending	
		end
	end
		



