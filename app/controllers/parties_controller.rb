######################################################################################
#
# This controller exists to allow Parties to identify Users through Contacts.
#
class PartiesController < ApplicationController

	before_filter :authenticate
	
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

		unless @party.update_attributes(params) then
			render 'edit' and return
		end

		if params[:previous_button] then
			@party.tranzaction.previous_step()
			redirect_to(edit_tranzaction_path(@party.tranzaction)) and return
		elsif params[:cancel_button] then
			@party.tranzaction.destroy()
			redirect_to tranzactions_path and return
		end

		descriptor_class = @party.tranzaction.namespaced_class(:ModelDescriptor)
		if	@party.contact_strategy == Contact::CONTACT_METHODS[0] then

			# Find
			contact = @party.contact
			matches = Contact.matching_contacts(
				contact.class,
				contact.data
			)
			if matches.empty? then
				notice = descriptor_class::PARTY_LOCATION_NOTICES[:not_found]\
							.gsub('%SITE_NAME%', SITE_NAME)\
							.gsub('%PARTY%', @party.contact.data)
				flash[:notice] = notice 
				@party.contact_strategy = Contact::CONTACT_METHODS[1]
				render 'edit' and return
			elsif matches.count > 1 then
			    render 'disambiguate' and return
			else
				@party.replace_contact(matches.first)
				@party.tranzaction.resume()
				notice = descriptor_class::PARTY_LOCATION_NOTICES[:resolved].gsub('%PARTY%', @party.dba)
				redirect_to(edit_tranzaction_path(@party.tranzaction),
					:notice => notice 
				) and return
			end

		elsif @party.contact_strategy == Contact::CONTACT_METHODS[1] 
			# Invite
			# TODO: send invitation to User from confirm page
			@party.tranzaction.resume()
			notice = descriptor_class::PARTY_LOCATION_NOTICES[:invite]\
						.gsub('%SITE_NAME%', SITE_NAME)\
						.gsub('%PARTY%', @party.dba(false))
			redirect_to(
				edit_tranzaction_path(@party.tranzaction),
				:notice => notice 
			) and return

		elsif @party.contact_strategy == Contact::CONTACT_METHODS[2] then

			# Associate
			contact = @party.get_associate_contact(current_user(), params)
			if contact.nil? then
				raise "selected user (id = '#{params[:associate_id]}') not found"
			else
				@party.replace_contact(contact)
				@party.tranzaction.resume()
				notice = descriptor_class::PARTY_LOCATION_NOTICES[:identified]\
						.gsub('%PARTY%', @party.dba(true))
				redirect_to(
					edit_tranzaction_path(@party.tranzaction),
					:notice => notice 
				) and return
			end

		elsif @party.contact_strategy == Contact::CONTACT_METHODS[3] then

			# Publish 
			# TODO: show invitation to User from confirm page
			@party.replace_contact(nil)
			@party.tranzaction.resume()
			notice = descriptor_class::PARTY_LOCATION_NOTICES[:published]
			redirect_to(edit_tranzaction_path(@party.tranzaction),
				:notice => notice 
			) and return
		else
			raise "invalid party identification method"
		end
	end

end
