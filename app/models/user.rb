
class User < ActiveRecord::Base
	require 'digest'

	has_one		:account, :inverse_of => :user, :dependent => :destroy
	has_many	:contacts, :inverse_of => :user, :dependent => :destroy

	attr_accessor :password
	attr_accessible :first_name, :last_name, :password, :username,
		:password_confirmation

	validates :first_name, 	:presence => true,
							:length => { :maximum => 50 }
	validates :last_name, 	:presence => true,
							:length => { :maximum => 50 }

	validates :password,	:presence			=> 	true,
							:confirmation 		=> true,
							:length				=> { :within => 6..40 }

	before_save :encrypt_password

	# Initialize a new user's account
	def monetize(name = "default")
		account = self.build_account(name: name)
		account.funds = 0
		account.hold_funds = 0
		account.funds_currency = "USD"
		account.save!
	end

	# Return true if the user's passsword matches the submitted password.
	def has_password?(submitted_password)
		self.encrypted_password == encrypt(submitted_password)
	end

	def User.authenticate(username, submitted_password)
		user = User.find_by_username(username) 

		return nil if user.nil?
		return user if user.has_password?(submitted_password)
	end

	def User.authenticate_with_salt(id, cookie_salt)
		user = find_by_id(id)
		(user && user.salt == cookie_salt) ? user : nil
	end

	# Contact uses this for lookup
	def User.find_by_contact_data(contact_data)
		User.find_by_username(contact_data)
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

end
