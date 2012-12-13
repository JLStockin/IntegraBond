module ContactsHelper

	def contact_types
		Contact.contact_types
	end

	def stringify_contact(contact)
		"#{contact.class.to_s.downcase}: #{contact.format_contact_data}"
	end

end
