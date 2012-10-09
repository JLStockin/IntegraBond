
class User < ActiveRecord::Base
	require 'digest'
	param_accessor :use_phone_as_primary
	
	EMAIL_REGEX = /^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/i
	PHONE_REGEX = /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/
		# replacement text: (\1) \2-\3

	has_one :account, :inverse_of => :user, :dependent => :destroy
	has_many :parties, :dependent => :destroy
	has_many :contracts, :through => :parties

	attr_accessor :password
	attr_accessor :phone
	attr_accessible :email, :phone, :first_name, :last_name, :password,
		:password_confirmation, :use_phone_as_primary

	accepts_nested_attributes_for :account

	
	validates :first_name, 	:presence => true,
							:length => { :maximum => 50 }
	validates :last_name, 	:presence => true,
							:length => { :maximum => 50 }

  	validates :email,		:presence => true,
							:format => { :with => EMAIL_REGEX },
							:uniqueness => { :case_sensitive => false }

  	validates :phone,		:presence => true,
							:format => { :with => PHONE_REGEX }

	validates :password,	:presence			=> 	true,
							:confirmation 		=> true,
							:length				=> { :within => 6..40 }

	before_save :encrypt_password, :normalize_phone_number
	after_initialize :format_phone_number

	def to_s
		ret = "email: #{email}, first_name: #{first_name}, last_name = #{last_name}, " \
			+ "passwd: #{password}, account: #{account}"
		ret
	end

	def primary_id
		pid = self.use_phone_as_primary.nil?\
			? self.email\
			: self.use_phone_as_primary ? self.phone : self.email
		pid
	end

	# Initialize a new user's account
	def monetize(name = "default")
		account = self.create_account(name: name)
		account.funds = 0
		account.hold_funds = 0
		account.save!
	end

	# Return true if the user's passsword matches the submitted password.
	def has_password?(submitted_password)
		self.encrypted_password == encrypt(submitted_password)
	end

	def User.authenticate(email, phone, submitted_password)
		user = nil
		
		user = User.find_by_email(email) unless email.nil? or email.empty?
		user = User.find_by_normalized_phone(User.normalize_phone_number(phone))\
			unless phone.nil? or phone.empty?

		return nil if user.nil?
		return user if user.has_password?(submitted_password)
	end

	def User.authenticate_with_salt(id, cookie_salt)
		user = find_by_id(id)
		(user && user.salt == cookie_salt) ? user : nil
	end

	def User.normalize_phone_number(str)
		str.delete("()-.").to_i
	end

	def User.format_phone_number(num)
		ActionController::Base.helpers.number_to_phone(num)
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

		def normalize_phone_number()
			self.normalized_phone ||= User.normalize_phone_number(self.phone)\
				unless self.phone.nil?
		end

		def format_phone_number()
			self.phone ||= User.format_phone_number(self.normalized_phone)\
				unless self.normalized_phone.nil?
		end

end
