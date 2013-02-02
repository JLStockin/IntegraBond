require 'spec_helper'

describe "Party Basics" do

	before(:each) do
		@tranz = prepare_test_tranzaction(Contracts::Test::TestContract)
		@party = @tranz.party1
		@contact = @tranz.party1.contact
	end

	it "should create an instance given valid attributes" do
		party = Contracts::Test::Party1.new()
		party.tranzaction_id = @tranz.id
		party.save!
	end

	it "should have a user identifier" do
		@party.should respond_to(:user_identifier)
		@party.user_identifier.should be == @contact.user.username
	end

	describe "update Contact" do
		before(:each) do
			@unresolved_contact = EmailContact.create!(contact_data: "joe_blow@example.com")
		end

		it "shouldn't update if we're using the same Contact" do
			@party.update_contact(@contact).should be_nil
		end

		it "should update if we're using a different Contact" do
			@party.update_contact(@unresolved_contact).should be == @unresolved_contact
		end

		it "should destroy old Contact if it doesn't point at a User" do
			@party.update_contact(@unresolved_contact)
			lambda do
				@party.update_contact(@contact)
			end.should change(Contact, :count).by(-1)
		end

		it "should *not* destroy the old Contact if it points to a User" do
			lambda do
				@party.update_contact(@unresolved_contact)
			end.should_not change(Contact, :count)
		end
	end
		
	it "should have a description" do
		@party.description.should be == "First Party"
	end

end

describe "Party resolution" do

	before(:each) do
		@tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
		@params = update_test_tranzaction(@tranz)
		@party = @tranz.party2
		@contact = @tranz.party2.contact
		@user = @tranz.party2.contact.user
	end

	describe "attribute accessors" do

		describe "used to map contact type to index" do

			it "should have a find_type_index method" do
				@party.should respond_to(:find_type_index)
			end

			it "should map to 1 if no Contact" do
				@party.contact_strategy == Contact::CONTACT_METHODS[0]
				@party.contact = nil 
				@party.find_type_index().should be == 1
			end

			it "should map to 1 if contact strategy isn't 'find'" do
				@party.contact_strategy == Contact::CONTACT_METHODS[3]
				@party.contact = @user.contacts[1]
				@party.find_type_index().should be == 1
			end

			it "should map to correct index" do
				@party.contact_strategy = Contact::CONTACT_METHODS[0]
				@party.contact = @user.contacts[1]
				@party.find_type_index().should be == \
					Contact.contact_types[@party.contact.class.to_s.to_sym]
			end

		end

		describe "used to fetch the find result" do

			it "should fetch data needed to create a new Contact" do
				@party.should respond_to(:get_find_strategy)
				@party.contact_strategy = Contact::CONTACT_METHODS[0]
				@party.contact = @user.contacts[1]
				result = @party.get_find_strategy(@params)
				result[0].should be == :EmailContact
				result[1].should be == "joe.blow@example.com"
			end

			it "should return nil if the type index was nil" do
				@params.merge(@party.ugly_prefix().to_sym => {:find_type_index => nil}) 
				@party.get_find_strategy(@params).should be_nil
			end

			it "should return nil if we're using a different Party location strategy" do
				@party.contact_strategy = Contact::CONTACT_METHODS[3]
				@party.get_find_strategy(@params).should be_nil
			end
		end

		describe "tranzaction associate" do 
			it "should have an associate_id() method" do
				@party.should respond_to(:associate_id)
			end

			it "should be nil if Party doesn't have a Contact" do
				@party.update_contact(nil)
				@party.associate_id.should be_nil
			end

			it "should be Contact's id if Party doesn't have a Contact" do
				@party.associate_id.should be == @contact.id
			end

			it "should have a get_associate_contact() method" do
				@party.should respond_to(:get_associate_contact)
			end

			describe "contact" do

				it "should be user's own first contact if associate_id is nil" do
					@party.contact_strategy = Contact::CONTACT_METHODS[2]
					@params.merge(@party.ugly_prefix.to_sym => {associate_id: nil})
					@party.get_associate_contact(@user, @params).id.should be\
						== @user.contacts[0].id 
				end

				it "should return the first Contact for the selected associate" do
					@party.contact_strategy = Contact::CONTACT_METHODS[2]
					@params.merge(@party.ugly_prefix.to_sym => {associate_id: 4})
					@party.get_associate_contact(@user, @params).id.should be\
						== User.find(@user.id).contacts[0].id
				end

				it "should return nil if this isn't the current Party location strategy" do
					@party.contact_strategy = Contact::CONTACT_METHODS[0]
					@params.merge(@party.ugly_prefix.to_sym => {associate_id: 4})
					@party.get_associate_contact(@user, @params).should be_nil
				end
			end
		end
			
	end

	describe "dba()" do

		it "should have a dba() method" do
			@party.should respond_to(:dba)
		end

		describe "with no Contact" do

			describe "when suffix requested" do
				it "should display the right thing" do 
					@party.contact = nil
					@party.dba(true).should be == "Party2 (unresolved party)"
				end
			end

			describe "when suffix not requested" do
				it "should display the right thing" do 
					@party.contact = nil
					@party.dba(false).should be == "Party2"
				end
			end
		end

		describe "with Contact, no user," do

			describe "suffix requested," do
				it "should display the right thing" do 
					@party.contact = FactoryGirl.build(:seller_email)
					@party.contact.user = nil
					@party.dba(true).should be == "seller@example.com (unresolved party)"
				end
			end

			describe "suffix not requested," do
				it "should display the right thing" do 
					@party.contact = FactoryGirl.build(:seller_email)
					@party.contact.user = nil
					@party.dba(false).should be == "seller@example.com"
				end
			end
		end

		describe "with Contact, User," do

			before(:each) do
				@party = resolve_party2(@tranz)
			end

			describe "suffix requested," do
				it "should display the right thing" do 
					@party.dba(true).should be == "Ms Buyer (buyer@example.com)"
				end
			end

			describe "suffix not requested," do
				it "should display the right thing" do 
					@party.dba(false).should be == "Ms Buyer"
				end
			end

		end

		describe "with invitation" do

			describe "when suffix requested" do
				it "should display the right thing" do 
					@party.contact = FactoryGirl.build(:seller_email)
					@party.invitation = FactoryGirl.build(:party2_invite)
					@party.dba(true).should be == "seller@example.com (invited to IntegraBond)"
				end
			end

			describe "when suffix not requested" do
				it "should display the right thing" do 
					@party.contact = FactoryGirl.build(:seller_email)
					@party.invitation = FactoryGirl.build(:party2_invite)
					@party.dba(false).should be == "seller@example.com"
				end
			end

		end
	end
end
