require 'spec_helper'

describe ClauseRole do

	before(:each) do
		@clause = FactoryGirl.create(:acceptance_clause)
		@role = FactoryGirl.create(:role)
		@clause_role = @clause.clause_role.build(:role_id => @role.id)
	end

	it "should create a new instance given valid attributes" do
		@clause_role.save
	end

	it "should have a clause attribute" do
		@clause_role.should respond_to(:clause)
	end

	it "should have the right clause" do
		@clause_role.clause.should == @clause
	end

	it "should have a role attribute" do
		@clause_role.should respond_to(:role)
	end

	it "should have the right role" do
		@clause_role.role.should == @role
	end

end

