require 'spec_helper'
require 'contact'

##############################################################################
#
# Helpers follow. 
#
module ContactTesting

	#
	# constants
	#
	USER_DATA = {
		:user1 =>\
		{
			first_name: "Chris", last_name: "Schille",
			password: "foobar",
			username: "user1@example.com"
		}, 
		:user2 =>\
		{
			first_name: "Sali", last_name: "Schille",
			password: "foobar",
			username: "user2@example.com"
		}
	}
	
	CONTACT_DATA = {
		:user1 =>\
		{
			EmailContact:		"user1@example.com",
			SMSContact:			"408-555-1002",
			UsernameContact:	"user1@example.com"
		},
	
		:user2 =>\
		{
			EmailContact:		"user2@example.com",
			SMSContact:			"408-555-1003",
			UsernameContact:	"user2@example.com"
		}
	}

	BAD_DATA = {
		EmailContact: "shmo.com",
		SMSContact: "555-abcd",
		UsernameContact: "fred" 
	}

	#
	# RSpec.configure {|c| c.extend(DescribeHelpers)} --
	# to make this available in any describe block
	#
	module DescribeHelpers 
		def test_contact_types
			CONTACT_DATA[:user1].keys
		end
	end

	#
	# RSpec.configure {|c| c.include(ItHelpers)} --
	# to make this available in any spec ('it') block
	#
	module ItHelpers
		#
		# Helpers
		# 

		def tested_contact_type?(sym)
			CONTACT_DATA.first[1].keys.include?(sym)
		end

		def users()
			USER_DATA.keys
		end
	
		def test_create_user(user_sym)
			User.create!(USER_DATA[user_sym])
		end
	
		def test_contact_data(user_sym, type)
			CONTACT_DATA[user_sym][type]
		end
	
		def create_new_user_and_contact(user_sym, contact_class_sym)
			user = test_create_user(user_sym)
			data = test_contact_data(user_sym, contact_class_sym)
			contact = Contact.new_contact(contact_class_sym, data)
			user.contacts << contact
			return [user, contact]
		end
	end
end


####################################################################################
#
# Shared examples begin here...
#
shared_examples_for "SMSContact" do

	before(:each) do
		@number_in = "(606)555-1212"
		@number_out = "6065551212"
	end

	["707-444-4045", "(707)555-1212", "800-354-2888", "(800) 438-1244"].each do |good_number|
		it "should allow '#{good_number}'" do
			instance.contact_data = good_number 
			instance.should be_valid
		end
	end

	["5434", "12-1234", "1-800-usaloan", "", "abcdefg"].each do |bad_number|
		it "should flag '#{bad_number}'" do
			instance.contact_data = bad_number 
			instance.should_not be_valid
		end
	end

	it "should display sms numbers with correct punctuation" do
		instance.contact_data = @number_in 
		instance.data.should be == ActionController::Base.helpers.number_to_phone(
			instance.contact_data.to_i
		)
	end

	it "should save sms numbers without punctionation" do
		instance.contact_data = @number_in 
		instance.save!
		instance.reload
		instance.contact_data.should be == @number_out 
		instance.data.should be == ActionController::Base.helpers.number_to_phone(
			instance.contact_data
		)
	end

end

shared_examples_for "UsernameContact" do

	before(:each) do
		@name = "Jeffro1228"
		@email = "Jeffro1228@Example.com"
	end

	["sally454", "cschille@example.com", "cschille", "typo_man"].each do |good_name|
		it "should allow '#{good_name}'" do
			instance.contact_data = good_name 
			instance.should be_valid
		end
	end

	["12:23", "", "abcde", "asdfasdfas dfasdfasdf asdfasdfas dfasdfaaaa fda4fac7d0"]\
			.each do |bad_name|
		it "should flag '#{bad_name}'" do
			instance.contact_data = bad_name 
			instance.should_not be_valid
		end
	end
	
	it "should display usernames in lowercase" do
		instance.contact_data = @name
		instance.data.should be == @name.downcase
	end

	it "should save usernames in lowercase" do
		instance.contact_data = @email 
		instance.save!
		instance.reload
		instance.data.should be == @email.downcase 
	end

end

shared_examples_for "EmailContact" do
	before(:each) do
		@email = "User200@Example.com" 
	end

	it "should display email address in lowercase" do
		instance.contact_data = @email 
		instance.data.should be == @email.downcase 
	end

	it "should save email addresses in lowercase" do
		instance.contact_data = @email 
		instance.save!
		instance.reload
		instance.data.should be == @email.downcase 
	end

	describe "normalize" do

		it "should be a method" do
			instance.should respond_to(:normalize)
		end

		it "should have a working instance method" do
			instance.contact_data = @email
			instance.normalize
			instance.contact_data.should be == @email.downcase 
		end

		it "should be a class method too" do
			instance.should respond_to(:normalize)
		end

		it "should have a working class method" do
			instance.class.normalize(@email).should be == @email.downcase 
		end
	end

end

describe Contact do

	RSpec.configure do |c|
		c.include ContactTesting::ItHelpers
		c.extend ContactTesting::DescribeHelpers
	end

	####################################################################################
	#
	# Tests begin here...
	#
	describe "#contact_types" do

		it "should be a class method" do
			Contact.should respond_to(:contact_types)
		end

	end

	describe "class not included in test suite(!): " do
		Contact.subclasses.keys.each do |sym|	
			it "#{sym.to_s}" do
				tested_contact_type?(sym).should be_true
			end
		end
	end

	describe "(Email)" do
		it_behaves_like "EmailContact" do
			let(:instance) {
				create_new_user_and_contact(:user1, :EmailContact)[1]
			}
		end
	end

	describe "(SMS)" do
		it_behaves_like "SMSContact" do
			let(:instance) {
				create_new_user_and_contact(:user1, :SMSContact)[1]
			}
		end
	end

	describe "(Username)" do
		it_behaves_like "UsernameContact" do
			let(:instance) {
				create_new_user_and_contact(:user1, :UsernameContact)[1]
			}
		end
	end


	describe "searching" do

		it "should be have ::matching_contacts" do
			Contact.should respond_to(:matching_contacts)
		end

		test_contact_types.each do |sym|

			it "should find one instance of #{sym.to_s}" do

				create_new_user_and_contact(:user1, sym)

				matches = Contact.matching_contacts(sym.to_s, test_contact_data(:user1, sym))
				matches.count.should be == 1
			end

			it "should find two instances of #{sym.to_s}" do
				contact = create_new_user_and_contact(:user1, sym)[1]
				# Create dup Contact for second User with 1st User's contact_data 
				user2 = create_new_user_and_contact(:user2, sym)[0]
				data = test_contact_data(:user1, sym)
				contact = Contact.new_contact(sym, data)
				user2.contacts << contact

				matches = Contact.matching_contacts(sym.to_s, data)
				matches.count.should be == 2
			end

			it "should find no instances of #{sym.to_s}" do

				result = Contact.matching_contacts(sym.to_s, test_contact_data(:user1, sym))
				result.count.should be == 0
			end
		end
	end

end
