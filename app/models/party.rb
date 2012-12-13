##############################################################################################
#
# Party -- connects a Contact for a User (and her Account) to a role in a Tranzaction.
#
##############################################################################################

class Party < ActiveRecord::Base

	attr_accessible :contact_id, :tranzaction_id, :contact_strategy
	attr_accessor :selected_associate

	belongs_to	:tranzaction, class_name: ::Contract, foreign_key: :tranzaction_id
	belongs_to	:contact
	accepts_nested_attributes_for :contact
	has_one		:invitation, dependent: :destroy

	scope :parties_for, lambda {|usr| joins{contact}.where{contact.user_id == usr.id}}

	validates	:tranzaction, presence: true

	def user_identifier
		self.contact.user.username
	end

	def update_contact(new_contact)
		old_contact = self.contact
		return if new_contact == old_contact

		self.contact = new_contact
		self.save!

		# destroy previous contact; destroys invitation too.
		if old_contact.user_id.nil? then
			Contact.destroy(old_contact.id) if old_contact.user_id.nil?
		end
	end

	#
	# Record last method used to lookup another party
	#
	def self.contact_strategys_list()
		ModelDescriptor::CONTACT_METHODS
	end

	#
	# Code that belongs on a decorator
	#
	def description(index=0)
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		descriptor_class::PARTY_DESCRIPTIONS[ActiveRecord::Base.const_to_symbol(self.class)][index]
	end

	#
	# Legal description of the User (to the greatest extent possible)
	#
	def dba()
		if self.contact.nil? then
			return "#{self.class.const_to_symbol(self.class)} (unresolved party)"
		elsif !self.invitation.nil?
			return "#{self.contact.contact_data} has been invited to IntegraBond" 
		elsif !self.contact.user.nil? then
			return "#{self.contact.user.first_name} #{self.contact.user.last_name}"\
				+ " as #{self.contact.user.username}"
		else
			return "#{self.contact.contact_data} (unresolved party)" 
		end
	end

end
