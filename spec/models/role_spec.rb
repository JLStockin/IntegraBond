require 'spec_helper'

describe Role do
	before(:each) do
		@attr = FactoryGirl.attributes_for(:role)
		@role = Role.new(@attr)
	end

	describe Role do

		it "should create a new instance given valid attributes" do
			@role = Role.create!(@attr)
		end

		it "should have clauses" do
			@role.should respond_to(:clauses)
		end

		it "should have a name" do
			@role.should respond_to(:name)
		end
	end

end
