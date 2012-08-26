
class User < ActiveRecord::Base
	require 'digest'

	EMAIL_REGEX = /^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/i

	has_one :account, :inverse_of => :user, :dependent => :destroy
	has_many :transactions

	attr_accessor :password
	attr_accessible :email, :first_name, :last_name, :password, :password_confirmation
	accepts_nested_attributes_for :account

	
	validates :first_name, 	:presence => true,
							:length => { :maximum => 50 }
	validates :last_name, 	:presence => true,
							:length => { :maximum => 50 }

  	validates :email, 	:presence => true,
						:format => { :with => EMAIL_REGEX },
						:uniqueness => { :case_sensitive => false }

	validates :password,	:presence			=> 	true,
							:confirmation 		=> true,
							:length				=> { :within => 6..40 }

	before_save :encrypt_password

	def to_s
		ret = "email: #{email}, first_name: #{first_name}, last_name = #{last_name}, " \
			+ "passwd: #{password}, account: #{account}"
		ret
	end

	# Initialize a new user's account
	def monetize(name = "default")
		account = self.create_account(name: name)
		account.available_funds = 0
		account.total_funds = 0
		account.save!
	end

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
