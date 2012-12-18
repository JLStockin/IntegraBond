require 'spec_helper'

class PartyTest < Party
end

class Transaction < ActiveRecord::Base 
end

describe PartyTest do
	it "should create a new instance given valid attributes" do
		contact = FactoryGirl.create(:buyer_phone)
		user.account.set_funds(1000, 50)
		@party = PartyTest.new()
		@party.user = user
		@trans = Contracts::Test::TestContract.create!()
		@party.contract = @trans 
		@party.save!
	end

	before(:each) do
		user = FactoryGirl.create(:buyer_user)
		user.account.set_funds(1000, 50)
		@trans = Contracts::Test::TestContract.create!()
		@party = PartyTest.new()
		@party.user = user
		@party.contract = @trans 
		@party.save!
		user2 = FactoryGirl.create(:seller_user)
		@party2 = PartyTest.new()
		@party2.user = user2
		@party2.contract = @trans 
		@party2.save!
	end

end
