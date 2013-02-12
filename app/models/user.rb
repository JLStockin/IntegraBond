
class User < ActiveRecord::Base
	require 'digest'

	has_one		:account, :dependent => :destroy
	has_many	:contacts, :dependent => :destroy

	attr_accessor :password
	attr_accessible :first_name, :last_name, :username,
		:email, :phone, :password, :password_confirmation,
		:active_contact

	param_accessor :_active_contact

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

	validates_associated	:contacts

	before_save				:encrypt_password, :monetize_account,
							:save_email, :save_phone

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
		return nil if self.new_record?
		self._active_contact.nil?\
			? get_contact("EmailContact").id\
			: Contact.find(self._active_contact).id
	end

	def active_contact=(id)
		self._active_contact = id
	end

	def email()
		return @email if @email
		c = get_contact("EmailContact")
		c.nil? ? nil : c.data
	end

	def email=(e)
		@email = e
	end

	def save_email()
		create_or_update_contact("EmailContact", @email) if @email
	end

	def phone()
		return @phone if @phone
		c = get_contact("SMSContact")
		c.nil? ? nil : c.data
	end

	def phone=(p)
		@phone = p
	end

	def save_phone()
		create_or_update_contact("SMSContact", @phone)
	end

	def create_or_update_contact(type, data)
		return nil if data.nil?
		c = get_contact(type)
		if c.nil? then
			c = Contact.new_contact(type.to_sym, data)
			self.contacts << c
		else
			c.data = data
			c.save!
		end
		c
	end

	if Rails.env.test? then
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

		def get_contact(the_type)
			return nil if self.new_record?
			the_type = the_type.to_s unless the_type.is_a?(String)
			c = self.contacts.empty? ? [] : self.contacts.where{type == the_type}
			c = c.empty? ? nil : c.first
		end

		# Initialize a new user's account
		def monetize_account(name = "default")
			if (self.new_record?) then
				account = self.build_account(name: name)
				account.funds = MZERO 
				account.hold_funds = MZERO 
			end
		end
end
