
class User < ActiveRecord::Base
	require 'digest'

	has_one		:account, :dependent => :destroy
	has_many	:contacts, :dependent => :destroy

	attr_accessor :password
	attr_accessible :first_name, :last_name, :password, :username, :password_confirmation,
		:email, :phone, :username_same_as_email, :active_contact

	param_accessor :_username_same_as_email, :_active_contact

	validates :first_name, 	:presence => true,
							:length => { :maximum => 50 }
	validates :last_name, 	:presence => true,
							:length => { :maximum => 50 }

	validates :username,	:presence			=> 	true,
							:uniqueness => { :case_sensitive => false },
							:length				=> { :within => 6..40 }

	validates :password,	:presence			=> 	true,
							:confirmation 		=> true,
							:length				=> { :within => 6..40 }

	validates_associated	:contacts,
							:unless => lambda { self.new_record? },
							:message => "User has no contacts"

	before_validation		:update_username
	before_save				:encrypt_password, :monetize_account

	# Return true if the user's passsword matches the submitted password.
	def has_password?(submitted_password)
		self.encrypted_password == encrypt(submitted_password)
	end

	def self.authenticate(username, submitted_password)
		user = User.find_by_username(username) 
		return nil if user.nil?
		return user if user.has_password?(submitted_password)
	end

	def self.authenticate_with_salt(id, cookie_salt)
		user = find_by_id(id)
		(user && user.salt == cookie_salt) ? user : nil
	end

	#
	# Methods that should be moved to a decorator 
	#
	def contact_list()
		ret = [] 
		self.contacts.each do |c|
			ret << [c.class::CONTACT_TYPE_NAME, c.id]
		end
		ret
	end

	def active_contact()
		if self._active_contact.nil? then
			self._active_contact = (self.contacts.nil? or self.contacts.empty?)\
				? nil\
				: get_contact("EmailContact").id
		end
		Contact.find(self._active_contact)
	end

	def active_contact=(id)
		self._active_contact = id
	end

	def username_same_as_email()
		_username_same_as_email = true if _username_same_as_email.nil?	
		_username_same_as_email 
	end

	def username_same_as_email=(flag)
		_username_same_as_email = flag
	end

	def email()
		return nil if self.new_record?
		c = get_contact("EmailContact")
		c.contact_data unless c.nil?
	end

	def email=(data)
		return if data.nil?
		c = create_or_update_contact("EmailContact", data)
		c.contact_data unless c.nil?
	end

	def phone()
		return nil if self.new_record?
		c = get_contact("SMSContact")
		c.contact_data unless c.nil?
	end

	def phone=(data)
		return if data.nil?
		c = create_or_update_contact("SMSContact", data)
		c.contact_data
	end

	if Rails.env.test? then
		def test_update_username()
			update_username()
		end
		def test_create_or_update_contact(type, data)
			create_or_update_contact(type, data)
		end
		def test_get_contact(the_type)
			get_contact(the_type)
		end
	end

	private
		def encrypt_password
			self.salt = make_salt if new_record?
			self.encrypted_password = encrypt(self.password)
		end

		def make_salt
			secure_hash("#{Time.now.utc}--#{self.password}")
		end

		def encrypt(string)
			secure_hash("#{self.salt}--#{string}")	
		end

		def secure_hash(string)
			Digest::SHA2.hexdigest(string)
		end

		def create_or_update_contact(type, data)
			c = get_contact(type)
			if c.nil? then
				c = Contact.new_contact(type.to_sym, data)
				self.contacts << c
			else
				c.contact_data = data
				c.save!
			end
			c
		end

		def get_contact(the_type)
			c = self.contacts.empty? ? [] : self.contacts.where{type == the_type}
			c = c.empty? ? nil : c.first
		end

		# Initialize a new user's account
		def monetize_account(name = "default")
			if (account.nil?) then
				account = self.build_account(name: name)
				account.funds = MZERO 
				account.hold_funds = MZERO 
			end
		end

		# Unless User has elected to break the link between username and the EmailContact,
		# use the email address as the username
		def update_username()
			e = get_contact("EmailContact")
			(self.username = e.contact_data if username_same_as_email()) unless e.nil?
		end
end
