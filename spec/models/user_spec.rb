require 'spec_helper'

describe User do
	
	before(:each) do
		@user = FactoryGirl.build(:seller_user)
		@email_contact = FactoryGirl.build(:seller_email) 
		$debug_this = false
	end

	it "should create a new instance given valid attributes" do
		@user.save!
		@user.contacts << @email_contact
		@email_contact.save!
		@user.save!
	end

	it "should save its children" do
		@user.save!
		@user.contacts << @email_contact
		@user.save!
		@user.contacts.count.should be >= 1
		@user.contacts.first.new_record?.should be_false
	end

	it "should require a first name" do
		@user.first_name = ""
		@user.should_not be_valid
	end

	describe "field length constraints" do
		before(:each) do
			@long_name = "a" * 51
		end

		it "should reject first names that are too long (>50 chars)" do
			@user.first_name = @long_name
			@user.should_not be_valid
		end

		it "should reject last names that are too long (>50 chars)" do
			@user.last_name = @long_name
			@user.should_not be_valid
		end
	end

	it "should require a last name" do
		@user.last_name = ""
		@user.should_not be_valid
	end

	it "should reject usernames identical up to case" do
		@user.save!
		dup_user = FactoryGirl.build(:seller_user)
		dup_user.username = @user.username.upcase() 
		dup_user.should_not be_valid 
	end

	# Password testing
	describe "password validations" do

		it "should require a password" do
			@user.password = ""
			@user.password_confirmation = ""
			@user.should_not be_valid
		end

		it "should require a matching password confirmation" do
			@user.password_confirmation = "invalid"
			@user.should_not be_valid
		end

		it "should reject short passwords" do
			short = "a" * 5
			@user.password = short
			@user.password_confirmation = short
			@user.should_not be_valid
		end

		it "should reject long passwords" do
			long = "a" * 41 
			@user.password = long 
			@user.password_confirmation = long 
			@user.should_not be_valid
		end
	end

	describe "password encryption" do

		before(:each) do
			@user.save!
			@user.contacts << @email_contact
		end

		it "should have an encrypted password attribute" do
			@user.should respond_to(:encrypted_password)
		end

		it "should set the encrypted password" do
			@user.encrypted_password.should_not be_blank
		end

		describe "has_password? method" do

			it "should be false if the passwords do not match" do
				@user.has_password?("invalid").should be_false
			end

			it "should be true if the passwords match" do
				@user.has_password?("foobar").should be_true
			end
		end

		describe "authenticate method" do

			it "should return nul on email/password mismatch" do
				wrong_password_user = User.authenticate(@user.username, "wrongpass")
				wrong_password_user.should be_nil
			end

			it "should return nil for a username with no user" do
				nonexistent_user = User.authenticate("bar@foo.com", @user.password)
				nonexistent_user.should be_nil
			end

			it "should return nil for a password with no user" do
				nonexistent_user = User.authenticate(nil, @user.password)
				nonexistent_user.should be_nil
			end

			it "should return the user on username/password match" do
				matching_user = User.authenticate(@user.username, @user.password) 
				matching_user.should == @user
			end

		end
	end

	describe "admin attribute" do

		it "should respond to admin" do
			@user.should respond_to(:admin)
		end

		it "should not be an admin by default" do
			@user.should_not be_admin
		end

		it "should be convertible to an admin" do
			@user.toggle!(:admin)
			@user.should be_admin
		end

	end

	describe "account" do

		it "should not have an Account when newly created" do
			@user.account.should be_nil
		end

		it "should have an Account after being saved" do
			@user.save!
			@user.reload
			@user.account.should_not be_nil
		end
	end

	describe "active contact" do

		before(:each) do

			@user.save!
			@user.contacts << @email_contact

			@phone_contact = FactoryGirl.create(:seller_sms)
			@user.contacts << @phone_contact

			@username_contact = FactoryGirl.create(:seller_username)
			@user.contacts << @username_contact
		end

		it "should have an active contact once saved" do
			@user.active_contact.should_not be_nil	
		end
		
		it "should default to EmailContact" do
			@user.active_contact.should be == @email_contact.id
		end

		it "should have working set and get" do
			@user.active_contact = @phone_contact.id 
			@user.active_contact.should be == @phone_contact.id
			@user.active_contact = @username_contact.id 
			@user.active_contact.should be == @username_contact.id
		end

		it "should persist" do
			@user.active_contact = @phone_contact.id 
			@user.save!
			@user.reload
			@user.active_contact.should be == @phone_contact.id
		end
	end

	describe "helpers" do

		before(:each) do
			@user.save!

			@user.contacts << @email_contact

			@phone_contact = FactoryGirl.build(:seller_sms) 
			@user.contacts << @phone_contact

			@email_update = "new_user@example.com"
			@phone_update = "707-555-0150"
			@phone_update_raw = "7075550150"
		end

		describe "(plumbing)" do

			before(:each) do
				@username_contact = FactoryGirl.create(:seller_username)
				@user.contacts << @username_contact
				@username_contact.save!
				@params = {
					@email_contact => "user_update@example.com",
					@phone_contact => "4085550101",
					@username_contact => @email_contact.contact_data
				}
			end

			describe "-- when the right Contact exists --" do

				it "should update value" do
					c = nil
					@params.each_pair do |o, data|
						expect {
							c = @user.create_or_update_contact(o.class.to_s, data)
						}.to_not change { Contact.count }
						c.should be == o 
						c.contact_data.should be == data
					end
				end
			end

			describe "-- when the right Contact doesn't exist --" do

				it "should create Contact" do
					c = nil
					@params.each_pair do |o, data|
						o.destroy()	
						expect {
							@user.reload
							c = @user.create_or_update_contact(o.class.to_s, data)
							c.save!
						}.to change { Contact.count }.by(1)
						c.should_not be_nil
						c.contact_data.should be == data 
					end
				end
			end

			it "get_contact should fetch an existing Contact" do
				@params.keys.each do |o|
					@user.test_get_contact(o.class.to_s).should be == o
				end
			end
			
			it "get_contact should return nil" do
				@params.keys.each do |o|
					o.destroy()
					@user.test_get_contact(o.class.to_s).should be_nil
				end
			end

		end

		it "(should have email getter and setter)" do
			@user.should respond_to(:email)
			@user.should respond_to(:email=)
		end

		it "(should have phone getter and setter)" do
			@user.should respond_to(:phone)
			@user.should respond_to(:phone=)
		end

		describe "when the right Contact exists," do

			describe "email" do
				it "should fetch the right value" do
					e = @user.email
					e.should be == @email_contact.contact_data
				end

				it "should set a new value" do
					expect {
						@user.email = @email_update
						@user.save!
					}.to_not change { Contact.count }
					@email_contact.reload
					@email_contact.contact_data.should be == @email_update 
				end
			end

			describe "phone" do
				it "should get the right value" do
					p = @user.phone
					p.should be == @phone_contact.data
				end

				it "should persist the right value" do
					expect {
						@user.phone = @phone_update
						@user.save!
					}.to_not change { Contact.count }
					@phone_contact.reload
					@phone_contact.data.should be == @phone_update
				end
			end

		end

		describe "when right Contact is missing," do

			describe "email" do
				before(:each) do
					@email_contact.destroy
				end
				it "should fetch nil" do
					e = @user.email
					e.should be_nil
				end

				it "should set a new value" do
					expect {
						@user.email = @email_update 
						@user.save!
					}.to change { Contact.count }.by(1)
					@user.email.should be == @email_update
				end
			end

			describe "phone" do
				before(:each) do
					@phone_contact.destroy
				end
				it "should fetch nil" do
					p = @user.phone
					p.should be_nil
				end

				it "should set a new value" do
					expect {
						@user.phone = @phone_update 
						@user.save!
					}.to change { Contact.count }.by(1)
					@user.phone.should be == @phone_update
				end
			end

		end

	end

end
