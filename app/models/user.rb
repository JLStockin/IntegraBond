
class User < ActiveRecord::Base
	require 'digest'

	attr_accessor :password
	attr_accessible :email, :name, :password, :password_confirmation

	has_many :accounts
	
	EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

	validates :name, 	:presence => true,
 						:length => { :maximum => 50 }

  	validates :email, 	:presence => true,
						:format => { :with => User::EMAIL_REGEX },
						:uniqueness => { :case_sensitive => false }

	validates :password,	:presence			=> 	true,
							:confirmation 		=> true,
							:length				=> { :within => 6..40 }

	before_save :encrypt_password

	# Return true if the user's passsword matches the submitted password.
	def has_password?(submitted_password)
		self.encrypted_password == encrypt(submitted_password)
	end

	def User.authenticate(email, submitted_password)
		user = find_by_email(email)
		return nil if user.nil?
		return user if user.has_password?(submitted_password)
	end

	def User.authenticate_with_salt(id, cookie_salt)
		user = find_by_id(id)
		(user && user.salt == cookie_salt) ? user : nil
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
