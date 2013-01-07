require 'squeel'

class Contact < ActiveRecord::Base
	INVITABLE_CONTACT_TYPES = [\
		:EmailContact\
	]

	CONTACT_METHODS = [
		"find",
		"invite",
		"associate",
		"publish"
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
	belongs_to		:user, inverse_of: :contacts
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
		self.contact_data.nil? ? nil : self.contact_data.downcase()
	end

	def data=(data)
		self.contact_data = self.class.normalize(data)
	end

	#
	#
	# If contact_data can be mapped to one or more resolved Contacts, return them.
	# Returns nil if no matching Contact(s) could be found.
	#
	def self.matching_contacts(contact_type, data)
		klass = contact_type.is_a?(Class) ? contact_type : contact_type.to_s.constantize()
		contacts = Contact.where{
			(type == contact_type.to_s) &\
			(contact_data == klass.normalize(data)) &\
			(user_id != nil)
		}
		return contacts
	end

	def self.create_contact(type, data)
		klass = type.to_s.constantize
		c = klass.new()
		c.contact_data = klass.normalize(data)
		c
	end

	# Private
	def normalize()
		self.data = self.contact_data # data= calls class normalize()
	end

	def self.normalize(d)
		d.downcase unless d.nil?
	end

end

module ContactValidatorsModule
	EMAIL_REGEX = /^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/i
	PHONE_REGEX = /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/
		# replacement text: (\1) \2-\3

	def _validate(record, pattern)
		record.errors[:contact_data] << "(#{record.contact_data}) is not valid" unless
			!record.contact_data.nil? and \
			!record.contact_data.empty? and \
			record.contact_data =~ pattern


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
								:length => { :within => USERNAME_RANGE }
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
		self.contact_data.nil?\
			? nil\
			: ActionController::Base.helpers.number_to_phone(self.contact_data.to_i) 
	end
		
	def data=(data)
		self.contact_data = self.class.normalize(data)
	end

# Private
	def self.normalize(data)
		data.delete("()-.") unless data.nil?
	end

end
