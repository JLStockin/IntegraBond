require 'spec_helper'

describe Party do
	before(:each) do
		@transaction = FactoryGirl.create(:transaction)
		@user = FactoryGirl.create(:user)
		@role = FactoryGirl.create(:role)
	end

	it "should create a new instance given valid attributes" do
		@party = Party.new 
		@party.transaction = @transaction
		@party.user = @user
		@party.role = @role
		@party.save!
	end
end
