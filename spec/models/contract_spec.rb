require 'spec_helper'

describe Contract do

	before(:each) do
		@attr = FactoryGirl.attributes_for(:contract)
	end

	it "should create a new instance given valid attributes" do
		@contract = Contract.create!(@attr)
	end

	it "should not create a new instance given invalid attributes" do
		@attr.merge!(:name => "")
		@contract = Contract.new(@attr)
		@contract.should_not be_valid
	end

	it "should have clauses" do
		@contract = Contract.new(@attr)
		@contract.should respond_to(:clauses)
	end

	it "should have a name" do
		@contract = Contract.new(@attr)
		@contract.should respond_to(:name)
	end

	it "should have a module name" do
		@contract = Contract.new(@attr)
		@contract.should respond_to(:ruby_module)
	end

	it "should have an author" do
		@contract = Contract.new(@attr)
		@contract.should respond_to(:author_id)
	end

	it "should have an author who is a user" do
		@contract = Contract.new(@attr)
		@contract.author = create_test_user
		@contract.save
		@contract.reload	# needed?
		User.find(@contract.author.id).should_not be_nil
	end

	it "should have tags" do
		@contract = Contract.new(@attr)
		@contract.should respond_to(:tags)
	end

	it "should have 'default' in tags" do
		@contract = Contract.new(@attr)
		@contract.tags.index(:default).should be
	end

end
