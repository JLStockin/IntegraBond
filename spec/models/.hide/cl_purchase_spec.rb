require 'spec_helper'

#
# Class-level validations for contracts (validations on superclass Transaction)
#
describe IBContracts::CLPurchase do

	before(:each) do
		@seller = FactoryGirl.create(:seller_user)
		goods = FactoryGirl.create(:valuable_seller_goods,
			url: "https://cragislist.com//as435errweafr",
			description: "C101 Rolex watch", price: Money.parse("$225"))
		bond = FactoryGirl.create(:valuable_seller_bond, CLPurchase::DEFAULT_BOND[PartySeller])
		fees = FactoryGirl.create(:valuable_fees, CLPurchase::DEFAULT_BOND[PartySeller])
		listing = FactoryGirl.create(:artifact_lsting, :sender PartySeller.new(@seller))
		initial_goal = FactoryGirl.create(:goal_offer)

		@trans	= CLPurchase.new()
		@trans.parties << @seller
		@trans.valuables << @goods
		@trans.valuables << @bond
		@trans.valuables << @fees
		@trans.artifacts << @listing 
		@trans.goals << @initial_goal
	end

	it "should create an instance with valid attributes" do
		@trans.save!
	end

	it "should have parties" do 
		@trans.should respond_to :parties
	end

	it "should have only the seller" do 
		@trans.parties.count.should be == 1
		roles.include?(PartyBuyer).should be_true
		#roles.include?(:seller).should be_true
	end

	it "should have valuables" do
		@trans.should respond_to :valuables
	end

	# it "should have four valuables: :seller_goods, :buyer_bond, :seller_bond, :fees" do
	#	@trans.valuables.count.should be == trans.xassets.count 

	it "should have three valuables: :seller_goods, :seller_bond, :fees" do
		valuables = [:ValuableSellerGoods, :ValuableSellerDeposit, :ValuableFees]
		@trans.valuables.count.should be == valuables.count 
		valuables.each do |valuable|
			trans.valuable(valuable).should_not be_nil 
		end
	end

	it "should have artifacts" do
		trans.should respond_to :artifacts
	end

	it "should have the right artifacts" do
		@trans.artifact(:ArtifactListing).should_not be_nil
	end

	it "should have goals" do
		trans.should respond_to :goals
	end

	it "should have the right goal" do
		@trans.goal(:GoalAccept).should_not be_nil
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
		



