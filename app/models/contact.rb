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
		self.subclasses[subclass.to_s.to_sym] = self.subclasses_index
		self.subclasses_index += 1
	end

	attr_accessible :type, :user_id, :contact_data
	attr_accessor	:type_index
	belongs_to		:user
	has_many		:parties
	has_many		:tranzactions, :through => :parties

	before_validation :normalize

	#
	# Does this Contact point to a User? 
	#
	def resolved?
		!self.user_id.nil?
	end

	def self.contact_types()
		self.subclasses
	end

	def data()
		self.contact_data.downcase()
	end

	def data=(data)
		self.contact_data = data.downcase()
	end

	#
	#
	# If contact_data can be mapped to one or more resolved Contacts, return them.
	# Returns nil if no matching User(s) could be found.
	#
	def self.get_contacts(contact_type, data)
		if contact_type.to_s == UsernameContact.to_s then
			return contact_type.joins{user}.where{user.username == data}
		else
			# Existing User? (contact_type == :EmailContact, :SMSContact, etc.)
			klass = contact_type.to_s.constantize
			contacts = Contact.where{\
				(type == contact_type.to_s) &\
				(contact_data == klass.normalize(data)) &\
				(user_id != nil)\
			}
			return contacts
		end
	end

	def self.create_contact(type, data)
		klass = type.to_s.constantize
		c = klass.new()
		c.contact_data = klass.normalize(data)
		c
	end

	# Private
	def normalize()
		self.data = self.contact_data
	end

	def self.normalize(data)
		data.downcase
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

#########################################################################################
#
# Subclasses
#

class UsernameContact < Contact
	USERNAME_RANGE = (8..40)
	CONTACT_TYPE_NAME = 'via username' 
	validates :contact_data, 	:presence => true,
								:length => { :in => USERNAME_RANGE }
end

class EmailContact < Contact
	validates_with EmailValidator

	CONTACT_TYPE_NAME = 'via email'
end

class SMSContact < Contact

	CONTACT_TYPE_NAME = 'via SMS (text)'

	validates_with SMSValidator

# Exposed through base class 
	def data()
		ActionController::Base.helpers.number_to_phone(self.contact_data.to_i)
	end
		
	def data=(data)
		self.contact_data = self.class.normalize(data)
	end

# Private
	def self.normalize(data)
		data.delete("()-.")
	end

end
