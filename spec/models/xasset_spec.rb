require 'spec_helper'

describe Xasset do
	before(:each) do
		@attr = FactoryGirl.attributes_for(:xasset)
	end


		it "should create a new instance given valid attributes" do
			@xasset = Xasset.create!(@attr) 
		end

		it "should have clauses" do
			@xasset = Xasset.new(@attr)
			@xasset.should respond_to(:clauses)
		end

		it "should have a name" do
			@xasset = Xasset.new(@attr)
			@xasset.should respond_to(:name)
		end

		it "should have an asset_type" do
			@xasset = Xasset.new(@attr)
			@xasset.should respond_to(:asset_type)
		end

end
