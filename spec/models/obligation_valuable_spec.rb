require 'spec_helper'

describe ObligationValuable do
	before(:each) do
		@obligation = FactoryGirl.create(:obligation)
		@valuable = FactoryGirl.create(:valuable)
		@obligation_valuable = @obligation.valuables.build
	end

	it "should create a new instance given valid attributes" do
		@obligation_valuable.save!
	end
end

