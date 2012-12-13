######################################################################################
#
# This controller exists to allow Parties to identify Users through Contacts.
#
class PartiesController < ApplicationController
	before_filter :authenticate
	
	attr_accessor :matching_parties

	#
	# Get /parties/:party_id/edit
	#
	def edit 
		@party = Party.find(params[:id].to_i)
		raise "party not found" if @party.nil?
	end

	#
	# Post /parties/:id
	#
	def update 
		@party = Party.find(params[:id].to_i)
		raise "party not found" if @party.nil?
		if params[:previous_button] then
			@party.tranzaction.previous_step()
			redirect_to(edit_tranzaction_path(@party.tranzaction))
			return
		end

		prefix = @party.class.to_s.downcase.gsub('::', '_').to_sym
		if params[prefix][:contact_strategy] == Contact::CONTACT_METHODS[0] then

			ti = params[:contact][:contact_type_index].to_i
			type = Contact.subclasses.key(ti)
			data =  params[:contact][:contact_data]
			contacts = Contact.get_contacts(type, data)
			if contacts.empty? then
				flash[:notice] = 	
					"#{SITE_NAME} user for '#{params[:contact][:contact_data]}' "\
						+ "could not be found.  Invite to #{SITE_NAME}?"
				render 'edit'
			elsif contacts.count == 1 # Just one
				@party.update_contact(contacts.first)
				if @party.save() then
					@party.tranzaction.resume()
					redirect_to(edit_tranzaction_path(@party.tranzaction),
						:notice => "Party identified: #{@party.dba}"\
					)
				end	
				return
			elsif contacts.count > 1
				render 'disambiguate' and return
			end
		elsif params[prefix][:contact_strategy] == Contact::CONTACT_METHODS[1]
			contacts = Contact.get_contacts(NullContact, params[:associate])
			if contact.empty? then
				raise "selected user '#{params[:associate]}' not found"
			else
				@party.update_contact(contacts.first)
				if (@party.save) then
					@party.tranzaction.resume()
					redirect_to(edit_tranzaction_path(@party.tranzaction),
						:notice => "Party identified: #{@party.contact.dba}")
				end
			end
			return
		elsif params[prefix][:contact_strategy] == Contact::CONTACT_METHODS[2]
			contact = PublishedContact.create!()
			@party.update_contact(contact)
			if @party.save() then
				@party.tranzaction.resume()
				redirect_to(edit_tranzaction_path(@party.tranzaction),
					:notice => "Offer published; any user can accept"\
				)
			end
			return
		else
			raise "invalid party identification method"
		end
	end

end
