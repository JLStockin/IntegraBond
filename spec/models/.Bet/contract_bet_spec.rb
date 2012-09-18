require 'spec_helper'

	describe "abort transaction" do

		before(:each) do
			@trans	= ContractBet.create!()
			@trans.start

		end

		it "should have a first goal" do
			@trans.goals[0].class.should be == IBContracts::Bet::ContractBet
		end

		it "should " do 
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
		



