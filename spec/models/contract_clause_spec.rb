require 'spec_helper'

describe ContractClause do

	before(:each) do
		@author = FactoryGirl.create(:user)
		@contract = FactoryGirl.create(:contract, :author_id => @author.id)
		@clause = FactoryGirl.create(:acceptance_clause, :author_id => @author.id)
		@contract_clause = @contract.contract_clause.build(:clause_id => @clause.id)
	end


		it "should create a new instance given valid attributes" do
			@contract_clause.save!
		end

		it "should have a contract attribute" do
			@contract_clause.should respond_to(:contract)
		end

		it "should have the right contract" do
			@contract_clause.contract.should ==  @contract
		end

		it "should have a clause attribute" do
			@contract_clause.should respond_to(:clause)
		end

		it "should have the right clause" do
			@contract_clause.clause.should ==  @clause
		end

end
