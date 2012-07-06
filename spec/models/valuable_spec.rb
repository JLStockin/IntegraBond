require 'spec_helper'

describe Valuable do
	before(:each) do
		@attr = FactoryGirl.attributes_for(:valuable)
	end

	it "should create a new instance given valid attributes" do
		@valuable = Valuable.create!(@attr) 
	end

end
