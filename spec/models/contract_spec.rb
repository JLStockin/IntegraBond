require 'spec_helper'

class Contracts::Test::BadContract; end

CONTRACT_LIST = [Contracts::Bet::ContractBet]

# Class-level validations for Contracts (validations on superclass Contract)
#

describe Contract do

	describe " meta-class" do

		before(:each) do
			@contracts = CONTRACT_LIST 
			@contract = @contracts[0]
		end

		it "should have found contract(s)" do
			@contracts.should_not be_nil
			@contracts.count.should be > 0
		end

		it "returns true for valid_contract? with a valid contract" do
			@contract.valid_contract?.should be_true
		end

		it "should error for valid_contract_type? with an invalid contract" do
			expect {Contracts::Test::BadContract.valid_contract?()}.should raise_error 
		end
	end

	describe ": class methods" do

		CONTRACT_LIST.each do |contract|

			before(:each) do
				@contract = contract
			end

			it "should have a name" do
				@contract.should respond_to(:name)
				@contract.name.should_not be_nil
			end

			it "should have a summary" do
				@contract.should respond_to(:summary)
			end

			it "should have an a valid email address for author" do
				@contract.should respond_to(:author)
			end

			it "should have tags" do
				@contract.should respond_to(:tags)
			end

			it "should be able to locate a valid tag" do
				@contract.contains_tag?(:default).should_not be_nil
			end

			it "should be unable to locate an invalid tag" do
				@contract.contains_tag?(:bunga).should be_false
			end

			it "should have a first goal" do
				@contract.should respond_to(:children)
			end

			it "should support an Artifact (on the Contract)" do
				@contract.should respond_to(:artifact)
			end

			it "should have an author email address" do
				@contract.should respond_to(:author_email)
			end

			it "should include party_roster" do
				@contract.should respond_to(:party_roster)
			end

			it "should have all the necessary constants" do
				@contract.valid_contract?.should be_true
			end

		end	

	end

end
