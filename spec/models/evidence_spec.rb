require 'spec_helper'

describe Evidence do
	before(:each) do
		@attr = FactoryGirl.attributes_for(:evidence)
		@obligation = FactoryGirl.build(:obligation)
	end

	it "should create a new instance given valid attributes" do
		@evidence = Evidence.create!(@attr)
	end

end
