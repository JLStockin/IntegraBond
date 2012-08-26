require 'spec_helper'

class PartyTest < Party
end

class Transaction < ActiveRecord::Base 
end

describe PartyTest do
	it "should create a new instance given valid attributes" do
		user = FactoryGirl.build(:buyer_user)
		user.account.set_funds(1000, 50)
		@party = PartyTest.new()
		@party.user = user
		transaction = Transaction.create!()
		@party.transaction = transaction
		@party.save!
	end

	before(:each) do
		user = FactoryGirl.build(:buyer_user)
		user.account.set_funds(1000, 50)
		transaction = Transaction.new()
		@party = PartyTest.new()
		@party.user = user
		@party.transaction = transaction
		user2 = FactoryGirl.build(:seller_user)
		@party2 = PartyTest.new()
		@party2.user = user2
		@party2.transaction = transaction
	end

end
