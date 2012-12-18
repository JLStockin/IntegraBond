require 'spec_helper'

class Transaction < ActiveRecord::Base

end

class ArtifactTest < Artifact
	PARAMS = [:a, :b]
end

describe ArtifactTest do
	before(:each) do
		@trans = Contracts::Test::TestContract.create!
		@af = ArtifactTest.new(contract_id: @trans.id) 
		@artifact = ArtifactTest.create!(contract_id: @trans.id) 
	end

	it "should create a new instance given valid attributes" do
		@af.save!
	end

	it "should have accessors" do
		@artifact.should respond_to :a
		@artifact.should respond_to :b
		@artifact.should respond_to :a=
		@artifact.should respond_to :b=
	end
		
	it "should have working accessors" do
		@artifact.a.should be_nil
		@artifact.b.should be_nil
		@artifact.a = 5
		@artifact.b = 10
		@artifact.a.should be == 5
		@artifact.b.should be == 10 
	end

	it "should have params that persist" do
		@artifact.a.should be_nil
		@artifact.b.should be_nil
		@artifact.a = 5
		@artifact.b = 10
		@artifact.save!
		@artifact.reload
		@artifact.a.should be == 5
		@artifact.b.should be == 10 
	end

	it "should support mass assignment defined" do
		@artifact.should respond_to :mass_assign_params
		@artifact.should respond_to :mass_fetch_params
	end

	it "should have working mass assignment accessors" do
		@artifact.mass_fetch_params.should be == {}
		@artifact.mass_assign_params( a: 5, b: 10 )
		hash = @artifact.mass_fetch_params
		hash[:a].should be ==  5
		hash[:b].should be == 10 
	end
			
	it "should have mass assignment accessors that persist data" do
		@artifact.mass_assign_params( a: 5, b: 10 )
		@artifact.save!
		@artifact.reload
		hash = @artifact.mass_fetch_params
		hash[:a].should be ==  5
		hash[:b].should be == 10 
	end
end
