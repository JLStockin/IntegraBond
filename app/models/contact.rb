require 'squeel'

class Contact < ActiveRecord::Base
	INVITABLE_CONTACT_TYPES = [\
		:EmailContact\
	]

	CONTACT_METHODS = [
		"find",
		"invite",
		"associate",
		"published"
	]

	class << self
		attr_accessor :subclasses
		attr_accessor :subclasses_index
	end
	self.subclasses = {} 
	self.subclasses_index = 1 


	def self.inherited(subclass)
		super
		unless subclass == PublishedContact then
			self.subclasses[subclass.to_s.to_sym] = self.subclasses_index
			self.subclasses_index += 1
		end
	end

	attr_accessible :contact_data, :user, :type
	attr_accessor	:user_id, :type_index
	belongs_to		:user
	has_many		:parties
	has_many		:tranzactions, :through => :parties

	def self.contact_types()
		self.subclasses
	end

	def self.lookup(type, str)
		contact_class = self.namespaced_class(type.to_s.camelize.to_sym)
		Contact.joins(:user).where(
			:contact_data => str, 
			:type => contact_class.to_s
		)
	end

	#
	# Overridden for special cases
	#
	def format_contact_data()
		self.contact_data
	end

	#
	# If contact_data can be mapped to one or more Contacts, return them.
	# Returns nil if no matching User(s) could be found. 
	#
	# UNTESTED!
	# 
	def self.get_contacts(contact_type, contact_data)
		if contact_type == NullContact then
			return Contact.joins{user}.where{user.username == contact_data}
		else
			# Existing User? (contact_type == :EmailContact, :SMSContact, etc.)
			contacts = Contact.lookup(\
				contact_type,
				contact_data\
			)
			return contacts
		end
	end

	#
	# UNTESTED!
	#
	def resolved?
		!self.user_id.nil?
	end

	#
	# Code that should live in a decorator
	#
	def self.contact_types_index()
		tuples = []
		self.subclasses.each_pair do |klass, index|
			tuples << [klass.to_s.constantize::CONTACT_TYPE_NAME, index] 
		end
		tuples
	end

	def contact_type_index()
		return Contact.subclasses[self.class.to_s.to_sym]
	end

	def user_contact_data
		dba()
	end

end

class EmailValidator < ActiveModel::Validator 
	include ContactValidatorsModule

	def validate(record)
		_validate(record, EMAIL_REGEX)
	end
end

class SMSValidator < ActiveModel::Validator 
	include ContactValidatorsModule

	def validate(record)
		_validate(record, PHONE_REGEX)
	end
end

class PublishedContact < Contact

	CONTACT_TYPE_NAME = 'publish (all users)'

	def format_contact_data()
		"published offer"
	end
end

class NullContact < Contact
	CONTACT_TYPE_NAME = 'via username' 
end

class EmailContact < Contact
	validates_with EmailValidator

	CONTACT_TYPE_NAME = 'via email'
end

class SMSContact < Contact
	attr_accessor :sms

	CONTACT_TYPE_NAME = 'SMS (text it)'

	validates_with SMSValidator

	before_validation :normalize_it
	after_initialize :format_it

	def format_contact_data()
		format_it
		self.sms
	end
		
	def normalize_it()
		self.contact_data = self.sms.delete("()-.")
	end

	def format_it()
		self.sms = ActionController::Base.helpers.number_to_phone(self.contact_data.to_i)
	end

end
