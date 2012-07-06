require 'spec_helper'

describe ObligationParty do
	before(:each) do
		@obligation = FactoryGirl.create(:obligation)
		@party = FactoryGirl.create(:party)
		@obligation_party = @obligation.parties.build
	end

	it "should create a new instance given valid attributes" do
		@obligation_party.save!
	end
end
