require 'spec_helper'

describe ClauseXasset do

	before(:each) do
		@clause = FactoryGirl.create(:acceptance_clause)	
		@xasset = FactoryGirl.create(:xasset)
		@clause_xasset = @clause.clause_xasset.build(:xasset_id => @xasset.id)
	end


	it "should create a new instance given valid attributes" do
		@clause_xasset.save!
	end

	it "should have an xasset" do
		@clause_xasset.should respond_to(:xasset)
	end

	it "should have the right xasset " do
		@clause_xasset.xasset.should ==  @xasset
	end

	it "should have a clause attribute" do
		@clause_xasset.should respond_to(:clause)
	end

	it "should have the right clause" do
		@clause_xasset.clause.should ==  @clause
	end
end

