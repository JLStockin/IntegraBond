require 'spec_helper'

CONTACT_TYPES_TO_TEST = [EmailContact, SMSContact, UsernameContact]

describe Contact do
	
	before(:each) do
		@user ||= FactoryGirl.create(:seller_user)
		@username = FactoryGirl.build(:seller_username_contact)
		@username.user_id = @user.id

		@email = FactoryGirl.build(:seller_email_contact)
		@email.user_id = @user.id

		@phone = FactoryGirl.build(:seller_sms_contact)
		@phone.user_id = @user.id
	end

	it "should test all Contacts" do
		Contact.contact_types.count.should be == 3
	end

	it "should have these contact types" do
		CONTACT_TYPES_TO_TEST.each do |klass|	
			Contact.subclasses.keys.include?(klass.to_s.to_sym).should be_true
		end
	end

	it "should create an instance given valid attributes" do
		@email.save!
		@phone.save!
		@username.save!
	end

	it "should flag bad email addresses" do
		contact = FactoryGirl.build(:seller_email_contact)
		contact.contact_data = "joe.com"
		contact.should_not be_valid
		contact.contact_data = ""
		contact.should_not be_valid
	end

	it "should flag a bad phone number" do
		contact = FactoryGirl.build(:seller_sms_contact)
		contact.contact_data = "foo"
		contact.should_not be_valid
		contact.contact_data = ""
		contact.should_not be_valid
	end

	it "should flag a bad username" do
		contact = FactoryGirl.build(:seller_username_contact)
		contact.contact_data = "foo"
		contact.should_not be_valid
		contact.contact_data = ""
		contact.should_not be_valid
	end

	describe "data reader" do

		it "should display usernames in lowercase" do
			contact = FactoryGirl.build(:seller_username_contact)
			contact.contact_data = "User100@Example.com"
			contact.data.should be == "user100@example.com"	
		end

		it "should save usernames in lowercase" do
			contact = FactoryGirl.build(:seller_username_contact)
			contact.contact_data = "User100@Example.com"
			contact.save!
			contact.data.should be == "user100@example.com"	

		end

		it "should display email address in lowercase" do
			contact = FactoryGirl.build(:seller_email_contact)
			contact.contact_data = "User200@Example.com"
			contact.data.should be == "user200@example.com"	
		end

		it "should save email addresses in lowercase" do
			contact = FactoryGirl.build(:seller_email_contact)
			contact.contact_data = "User200@Example.com"
			contact.save!
			contact.data.should be == "user200@example.com"	
		end

		it "should display phone numbers with correct punctuation" do
			contact = FactoryGirl.build(:seller_sms_contact)
			contact.contact_data = "6065551212"
			contact.data.should be == ActionController::Base.helpers.number_to_phone(
				contact.contact_data
			)
		end

		it "should save phone numbers without punctionation" do
			contact = FactoryGirl.build(:seller_sms_contact)
			contact.contact_data = "(606)555-1212"
			contact.save!
			contact.contact_data.should be == "6065551212"
			contact.data.should be == ActionController::Base.helpers.number_to_phone(
				contact.contact_data
			)
		end

	end

	describe "normalize" do
		before(:each) do
			@c = EmailContact.new
			@c.user = User.find(3)
			@data = "User2@Example.com"
			@c.contact_data = @data
		end

		it "should have a working instance method" do
			@c.normalize
			@c.contact_data.should be == @data.downcase 
		end

		it "should have a working class method" do
			@c.class.normalize(@data).should be == @data.downcase 
		end
	end

	describe "data writer" do

		it "should write usernames in lowercase" do
			contact = FactoryGirl.build(:seller_username_contact)
			contact.data = "User300@Example.com"
			contact.data.should be == "user300@example.com"	
			contact.save!
			contact.reload
			contact.contact_data.should be == "user300@example.com"	
			contact.data.should be == "user300@example.com"
		end

		it "should write email address in lowercase" do
			contact = FactoryGirl.build(:seller_email_contact)
			contact.data = "User400@Example.com"
			contact.data.should be == "user400@example.com"	
			contact.save!
			contact.reload
			contact.contact_data.should be == "user400@example.com"	
			contact.data.should be == "user400@example.com"
		end

		it "should write phone numbers without punctuation" do
			contact = FactoryGirl.build(:seller_sms_contact)
			contact.data = "5055551212"
			contact.save!
			contact.reload
			contact.contact_data.should be == "5055551212"
			contact.data.should be == ActionController::Base.helpers.number_to_phone(
				contact.contact_data
			)
		end

	end

	describe "get_contacts" do

		it "should have this class method" do
			Contact.should respond_to(:get_contacts)
		end

		it "should work for each type" do
			CONTACT_TYPES_TO_TEST.each do |klass|
				key = "seller_#{klass.to_s.underscore}"
				contact_data = FactoryGirl.attributes_for(key)[:contact_data] 
				c = klass.new()
				c.contact_data = ((klass == UsernameContact) ? @user.username : contact_data)
				c.user_id = @user.id 
				c.save!
				result = Contact.get_contacts(
					klass,
					klass == UsernameContact ? @user.username : contact_data
				)
				result.count.should be >= 1
			end
		end

		it "should return multiple objects where appropriate" do
			dup = FactoryGirl.build(:seller_email_contact)
			dup.user_id = 4
			dup.save!
			dup = FactoryGirl.build(:seller_email_contact)
			dup.user_id = 5
			dup.save!
			Contact.get_contacts(dup.class, dup.contact_data).count.should be >= 2
		end

		it "should fail gracefully" do
			Contact.get_contacts(EmailContact, "putz@foo.bar").empty?.should be_true
		end
	end

	describe "create_contact" do

		it "should create all Contact types" do
			CONTACT_TYPES_TO_TEST.each do |klass|
				c = Contact.create_contact(
					klass,
					(klass == SMSContact)\
						? "1005551212"\
						: "highnoon@example.com"
				)
				c.should be_valid
			end
		end
	end

	it "email should have a resolved? method" do
		@email.should respond_to(:resolved?)
		@email.resolved?.should be_true
	end

	it "phone should have a resolved? method" do
		@phone.should respond_to(:resolved?)
		@phone.resolved?.should be_true
	end

	it "username should have a resolved? method" do
		@username.should respond_to(:resolved?)
		@username.resolved?.should be_true
	end

	describe "types" do
		it "should be a class method on Contact" do
			Contact.should respond_to(:contact_types)
		end

		it "should return three tuples" do
			Contact.contact_types.count.should be == 3
		end

		it "hashes should consist of a symbol and an index number" do
			key = Contact.contact_types.keys[0]	
			key.instance_of?(Symbol).should be_true
			Contact.contact_types[key].instance_of?(Fixnum).should be_true
		end
	end

end
