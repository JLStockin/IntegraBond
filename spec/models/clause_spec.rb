require 'spec_helper'

describe Clause do

	before(:each) do
		@attr = FactoryGirl.attributes_for(:acceptance_clause)
	end

		it "should create a new instance given valid attributes" do
			@clause = Clause.create!(@attr) 
		end

		it "should have roles" do
			@clause = Clause.new(@attr)
			@clause.should respond_to(:roles)
		end

		it "should have contracts using it" do
			@clause = Clause.new(@attr)
			@clause.should respond_to(:contracts)
		end

		it "should have transaction assets" do
			@clause = Clause.new(@attr)
			@clause.should respond_to(:xassets)
		end

		it "should have a name" do
			@clause = Clause.new(@attr)
			@clause.should respond_to(:name)
		end

		it "should have a module name" do
			@clause = Clause.new(@attr)
			@clause.should respond_to(:ruby_module)
		end

		it "should have an author" do
			@clause = Clause.new(@attr)
			@clause.should respond_to(:author_id)
		end

		it "should have an author who is a user" do
			@clause = Clause.new(@attr)
			@clause.author = create_test_user
			@clause.save
			@clause.reload # needed?
			User.find(@clause.author.id).should_not be_nil
		end

		it "should have relative milestones" do
			@clause = Clause.new(@attr)
			@clause.should respond_to(:relative_milestones)
		end

		it "should have valid milestones" do
			@clause = Clause.new(@attr)
			@clause.relative_milestones = [ { :accept => { hours: 24 } } ]
			now = DateTime.now
			tomorrow = now.advance(@clause.relative_milestones[0][:accept])
		end

end
