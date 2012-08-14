require 'spec_helper'

describe Party do
	before(:each) do
		@transaction = FactoryGirl.create(:"ib_contracts/contract_no_goodies")
		@transaction.build_party(FactoryGirl.attributes_for(:buyer_party))
	end

	it "should create a new instance given valid attributes" do
		@party.save!
	end
end
