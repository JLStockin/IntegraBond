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
		@party.update_attributes(params)

		if params[:previous_button] then
			@party.tranzaction.previous_step()
			redirect_to(edit_tranzaction_path(@party.tranzaction)) and return
		end

		if	@party.contact_strategy == Contact::CONTACT_METHODS[0] then

			# Find
			contact = @party.contact
			matches = Contact.matching_contacts(
				contact.class,
				contact.contact_data
			)
			if matches.empty? then
				flash[:notice] = 	
					"#{SITE_NAME} user for '#{@party.contact.contact_data}' "\
						+ "could not be found.  Invite to #{SITE_NAME}?"
				@party.contact_strategy = Contact::CONTACT_METHODS[1]
				render 'edit' and return
			elsif matches.count > 1 then
			    render 'disambiguate' and return
			else
				@party.update_contact(matches.first)
				@party.tranzaction.resume()
				redirect_to(edit_tranzaction_path(@party.tranzaction),
					:notice => "Party #{@party.dba} resolved"\
				) and return
			end

		elsif @party.contact_strategy == Contact::CONTACT_METHODS[1] 
			# Invite
			# TODO: send invitation to User from confirm page
			@party.tranzaction.resume()
			redirect_to(
				edit_tranzaction_path(@party.tranzaction),
				:notice => "#{@party.dba(false)} will be invited to #{SITE_NAME}"
			) and return

		elsif @party.contact_strategy == Contact::CONTACT_METHODS[2] then

			# Associate
			contact = @party.get_associate_contact(current_user(), params)
			if contact.nil? then
				raise "selected user (id = '#{params[:associate_id]}') not found"
			else
				@party.update_contact(contact)
				@party.tranzaction.resume()
				redirect_to(
					edit_tranzaction_path(@party.tranzaction),
					:notice => "Party identified: #{@party.dba(true)}"
				) and return
			end

		elsif @party.contact_strategy == Contact::CONTACT_METHODS[3] then

			# Publish 
			# TODO: show invitation to User from confirm page
			@party.update_contact(nil)
			@party.tranzaction.resume()
			redirect_to(edit_tranzaction_path(@party.tranzaction),
				:notice => "Offer will be published (made available to any user)"
			) and return
		else
			raise "invalid party identification method"
		end
	end

end
