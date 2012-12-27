require 'spec_helper'

describe Contracts::Test::Party1 do

	before(:each) do
		@tranzaction = Contracts::Test::TestContract.create!()
		@user = User.find(3); raise "no users" if @user.nil?
		@contact = @user.contacts[0]
		@contact2 = @user.contacts[1]
		@unresolved_contact = Contact.create_contact(EmailContact, @contact.user.username) 
		@unresolved_contact.save!
		@party = Contracts::Test::Party1.new(@attr)
		@party.tranzaction = @tranzaction
		@party.contact = @contact
		@attr = {
			tranzaction_id: @tranzaction.id,
			contact_id: @contact.id
		}
		@params = {
			@party.ugly_prefix().to_sym() => {:find_type_index => "2"},
			:contact => { :contact_data => "joeblow@example.com" }
		}
	end

	it "should create an instance given valid attributes" do
		@party.save!
	end

	it "should have a user identifier" do
		@party.should respond_to(:user_identifier)
		@party.user_identifier.should be == @contact.user.username
	end

	describe "update contact" do
		it "shouldn't update if we're using the same Contact" do
			before = Contact.count
			@party.update_contact(@contact).should be_nil
			Contact.count.should be == before
		end

		it "should update if we're using a new Contact" do
			before = Contact.count
			@party.update_contact(@contact2).should be == @contact2
			Contact.count.should be == before
		end

		it "should destroy the old Contact if it doesn't point at a User" do
			before = Contact.count
			id = @unresolved_contact.id
			Contact.find(id).id.should be == id 
			@party.update_contact(@unresolved_contact).should be == @unresolved_contact
			Contact.count.should be == before
			@party.update_contact(@contact2).should be == @contact2
			Contact.count.should be == before - 1
			expect {Contact.find(id)}.should raise_error
		end

		it "should *not* destroy the old Contact if it points to a User" do
			before = Contact.count
			id = @contact2.id
			Contact.find(id).id.should be == id 
			@party.update_contact(@contact2).id.should be == @contact2.id
			Contact.find(id).id.should be == id
			Contact.count.should be == before
		end
	end
		
	it "should have a description" do
		@party.description.should be == "First Party"
	end

	describe "dba()" do

		it "should have a dba() method" do
			@party.should respond_to(:dba)
		end

		it "should mention the username and that it's unresolved if there's no Contact "\
				+ "or the Contact has no User" do
			@party.contact = nil
			@party.dba.should be == "Party1 (unresolved party)"
		end

		it "should mention the username and that it's unresolved if Contact has no User" do
			@party.update_contact(@unresolved_contact)
			@party.dba.should be == "user1@example.com (unresolved party)"
		end

		it "should have user's first, last and username in dba() "\
				+ "if fully resolved, but no invite" do 
			@party.dba.should be == "Chris Schille as user1@example.com"
		end

		it "should have username if invitation issued" do
			@party.update_contact(@unresolved_contact)
			invitation = Invitation.new()
			invitation.party = @party
			invitation.save!
			@party.dba.should be == "user1@example.com has been invited to IntegraBond"
		end
	end

	describe "attribute accessors" do
		describe "map contact type to index in type list" do

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

		describe "get find result" do
			it "should fetch data needed to create a new Contact" do
				@party.should respond_to(:get_find_strategy)
				@party.contact_strategy = Contact::CONTACT_METHODS[0]
				@party.contact = @user.contacts[1]
				result = @party.get_find_strategy(@params)
				result[0].should be == :EmailContact
				result[1].should be == "joeblow@example.com"
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
end
