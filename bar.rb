
######################################################################################
#
# This controller exists to allow Parties to identify Users through Contacts.
#
class PartiesController
	
	def create
		@party = Party.find(params[:party_id])
		raise "party not found" if party.nil?

		if params[:contact_method]  == Contact::CONTACT_METHODS[0] then
			contacts = Contact.get_contacts(params[:type], params[:contact_data])
			if contacts.nil? then
				party.errors[:base]\
					<< "#{SITE_NAME} user for '#{params[:contact_data]}' could not be found"
			elsif contacts.count == 1
				party.contact = contacts[0]
				(\
					redirect_to(edit_tranzactions_path(party.tranzaction),
						:flash => "Party identified: #{party.contact.dba}"\
					)\
					and return\
				) if party.save()
			elsif contacts.count > 1
				render '_disambiguate' and return
			end
		elsif params[:contact_method] == Contact::CONTACT_METHODS[1]
			contact = Contact.find_by_username(params[:associate])
			if contact.nil? then
				raise "selected user '#{params[:associate]}' not found"
			else
				flash "Party identified: #{party.contact.dba}"
				(redirect_to edit_tranzactions_path party.tranzaction) and return
			end
		elsif params[:contact_method] == Contact::CONTACT_METHODS[1]
			contact = PublishedContact.create!()
			party.contact = contact
			(\
				redirect_to(edit_tranzactions_path(party.tranzaction),
					:flash => "Offer published; any user can accept"\
				)\
				and return\
			) if party.save
		else
			raise "invalid party identification method"
		end
	end

end
