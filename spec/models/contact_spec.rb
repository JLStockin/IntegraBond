require 'spec_helper'

describe Contact do
	
	before(:each) do
		@email_attr = FactoryGirl.attributes_for(:seller_email_contact)
		@phone_attr = FactoryGirl.attributes_for(:seller_phone_contact)
		@user = FactoryGirl.create(:seller_user)
		@email = @user.build_email(@email_attr)
		@phone = @user.build_phone(@phone_attr)
	end

	it "should create an instance given valid attributes" do
		@email.save!
		@phone.save!
	end

	it "should flag bad contact data as invalid" do
		@email = @user.build_email(FactoryGirl.attributes_for(:seller_phone_contact))
		@phone = @user.build_phone(FactoryGirl.attributes_for(:seller_email_contact))
		@email.should_not be_valid
		@phone.should_not be_valid
	end

	it "it should be valid and save without a user" do
		@email = Email.new(@email_attr) 
		@email.should be_valid
		@email.save!
	end
end
