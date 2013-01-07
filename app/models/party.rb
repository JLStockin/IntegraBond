##############################################################################################
#
# Party -- connects a Contact for a User (and her Account) to a role in a Tranzaction.
#
##############################################################################################

class Party < ActiveRecord::Base

	attr_accessible :contact_id, :tranzaction_id, :contact_strategy

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
		return nil if new_contact == old_contact

		self.contact = new_contact
		self.save!

		# Destroy previous contact
		if !old_contact.nil? and old_contact.user_id.nil? then
			Contact.destroy(old_contact.id) # if !old_contact.nil? and old_contact.user_id.nil?
		end

		new_contact
	end

	def create_and_update_contact(params)
		contact_type = Contact.subclasses.key(
			params[self.ugly_prefix][:find_type_index].to_i
		)
		contact_data = params[:contact][:contact_data]
		contact = Contact.create_contact(
			contact_type,
			contact_data	
		)
		self.update_contact(contact)
	end

	def update_attributes(params)
				
		if params.has_key?(self.ugly_prefix) then
			self.contact_strategy = params[self.ugly_prefix][:contact_strategy]

			if (self.contact_strategy == Contact::CONTACT_METHODS[0]) then

				# find
				self.create_and_update_contact(params)

			elsif (self.contact_strategy  == Contact::CONTACT_METHODS[1])
				
				# invite
				self.create_and_update_contact(params)

				# TODO: create Invitation

			elsif (self.contact_strategy == Contact::CONTACT_METHODS[2])

				# associate
				user_id = params[self.ugly_prefix()][:associate_id].to_i
				begin
					user = User.find(user_id)
				rescue ActiveRecord::RecordNotFound => exc
					raise "associate not found"
				end

				self.update_contact(user.contacts.first)

			elsif (self.contact_strategy == Contact::CONTACT_METHODS[3])

				# published 
				self.update_contact(nil)

				# TODO: create Invitation
			end
		else
			raise "party attribute data not found in params"
		end
	end

	#
	# Code that belongs on a decorator
	#
	def description()
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		descriptor_class::PARTY_DESCRIPTIONS[ActiveRecord::Base.const_to_symbol(self.class)]
	end

	#
	# Legal description of the User (to the greatest extent possible)
	#
	def dba(verbose=false)
		suffix = verbose ? " (unresolved party)" : "" 

		if self.contact.nil? then
			ret = "#{self.class.const_to_symbol(self.class)}"
		elsif !self.invitation.nil?
			suffix = " (invited to #{SITE_NAME})"
			ret = "#{self.contact.data}"
		elsif !self.contact.user.nil? then
			suffix = " (#{self.contact.user.username})"
			ret = "#{self.contact.user.first_name} #{self.contact.user.last_name}"
		else
			ret = "#{self.contact.data}"
		end
		ret + (verbose ? suffix : "")
	end

	#############################################################################
	#
	# Code that should live in a decorator, not in the model
	#
	# Virtual attribute accessors for the various UI fields that ultimately
	# create or select a Contact
	#

	# Return the element that should be selected in the find select box 
	#
	def find_type_index()
		if self.contact_strategy == Contact::CONTACT_METHODS[0] \
				or self.contact_strategy == Contact::CONTACT_METHODS[1] then
			return self.contact.nil?\
				? 1\
				: Contact.subclasses[self.contact.class.to_s.to_sym]
		else
			return 1 
		end
	end

	# Map the element selected in the find box back to a [Contact subclass, data]
	# tuple.
	#
	def get_find_strategy(params)
		if self.contact_strategy == Contact::CONTACT_METHODS[0] then
			idx = (params[self.ugly_prefix()][:find_type_index]).to_i
			contact_type = idx.nil? \
				? Contact.contact_types.keys.first\
				: Contact.contact_types.key(idx) 
			data = params[:contact][:contact_data]
			return [contact_type, data] 
		else
			return nil
		end
	end

	# Return the element that should be selected in the associate select box
	# 2nd value of tuple is a Contact id.
	#
	def associate_id()
		return self.contact.nil?\
			? nil \
			: self.contact.id
	end

	def get_associate_contact(current_user, params)
		if self.contact_strategy == Contact::CONTACT_METHODS[2] then
			user_id = params[self.ugly_prefix()][:associate_id] 
			return user_id.nil? ? current_user.contacts.first : User.find(user_id).contacts.first
		else
			return nil 
		end

	end

	def ugly_prefix()
		self.class.to_s.downcase.gsub('::', '_').to_sym
	end

end
