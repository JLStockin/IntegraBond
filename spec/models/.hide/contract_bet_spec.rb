require 'spec_helper'

#
# Class-level validations for contracts (validations on superclass Transaction)
#

	it "should be able to write and read params a, b in _data" do
		@goal.a = "a"
		@goal.b = "b"
		@goal.save!
		id = @goal.id
		g = Goal.find(id)
		g.a.should be == "a"
		g.b.should be == "b"
	end

	it "should do the right thing with event start" do
		pending
	end

	it "should do the right thing with event provision" do
		pending
	end


	before(:all) do

		@trans	= ContractBet.new()

		@artifact
		results = {}
		results[:PartyParty1] = Random.rand(2)
		results[:PartyParty2] = results[:PartyParty1] == 0 ? 1 : 0
		af.results = results 
		@trans.artifacts << af 
		@trans.goals << @initial_goal
	end

	describe "initial setup" do
		it "should create an instance with valid attributes" do
			@trans.save!
		end

		it "should have parties" do 
			@trans.should respond_to :parties
		end

		it "should have just Party1" do 
			@trans.parties.count.should be == 1
			ContractBet.parties.include?(:PartyParty1).should be_true
			@trans.parties.include?(PartyParty1).should be_true
		end

		it "should have valuables" do
			@trans.should respond_to :valuables
		end

		it "should have two valuables: ValuableParty1Bet, ValuableParty1Fees" do
			valuables = [:IBContracts::Bet::ValuableParty1Bet,
				:IBContracts::Bet::ValuableParty1Fees]
			@trans.valuables.count.should be == valuables.count 
			valuables.each do |valuable|
				trans.valuable(valuable).should_not be_nil
			end
		end

		it "should have goals" do
			trans.should respond_to :goals
		end

		it "should have the right goal" do
			@trans.goal(:GoalAccept).should_not be_nil
		end
		
		it "should have artifacts" do
			trans.should respond_to :artifacts
		end

		it "should have the right artifacts" do
			@trans.artifact(:ArtifactListing).should_not be_nil
		end
	end

	describe "Party2 accepts" do

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
end
		



