class InvitationCallbackHook
	def self.before_save(invitation)
		invitation.create_slug()
	end
end

class Invitation < ActiveRecord::Base
	attr_accessor :type, :slug
	belongs_to :party
	belongs_to :contact

	before_save InvitationCallbackHook	

	#
	# :contact_data for the old and new contacts must match for a private invitation.
	# This means that a new user must create an account using the same :contact_data,
	# and accept an Invitation using this :contact_data.  Thereafter, the User is free
	# to change to a new Contact for herself in this Tranzaction.
	#
	def can_accept?(new_contact)
		return true if new_contact.is_a?(PublishedContact)
		return false if new_contact.resolved?()
		return self.contact.contact_data == new_contact.contact_data
	end

	def invite()
		# TODO
	end

	def create_slug
		self.slug ||= "#{party.tranzaction_id}{DateTime.now.to_i}"
	end
end
