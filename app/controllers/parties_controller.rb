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
		@party.contact_strategy = params[@party.ugly_prefix()][:contact_strategy]

		raise "party not found" if @party.nil?

		if params[:previous_button] then
			@party.tranzaction.previous_step()
			redirect_to(edit_tranzaction_path(@party.tranzaction))
			return
		end

		if	@party.contact_strategy == Contact::CONTACT_METHODS[0] or\
			@party.contact_strategy == Contact::CONTACT_METHODS[1] then

			# Find or Invite
			result = @party.get_find_result(params)
			matches = Contact.get_contacts(result[0], result[1])

			if @party.contact.nil? or @party.contact.class.to_s != result[0] then
				contact = Contact.create_contact(result[0], result[1])
				@party.update_contact(contact)
			elsif @party.contact.contact_data != result[1]
				@party.contact.contact_data = result[1]
				@party.contact.save!
			end

			if matches.empty? then
				if @party.contact_strategy == Contact::CONTACT_METHODS[0] then
					flash[:notice] = 	
						"#{SITE_NAME} user for '#{@party.contact.contact_data}' "\
							+ "could not be found.  Invite to #{SITE_NAME}?"
					@party.contact_strategy = Contact::CONTACT_METHODS[1]
					render 'edit' and return
				elsif @party.contact_strategy == Contact::CONTACT_METHODS[1] then
					@party.tranzaction.resume()
					redirect_to(
						edit_tranzaction_path(@party.tranzaction),
						:notice => "Offer will be published; any user can accept"
					) and return
				end
			elsif matches.count == 1 # Just one
				@party.update_contact(matches.first)
				@party.tranzaction.resume()
				redirect_to(edit_tranzaction_path(@party.tranzaction),
					:notice => "Party identified: #{@party.dba}"\
				)
				return
			elsif matches.count > 1
				render 'disambiguate' and return
			end

		elsif @party.contact_strategy == Contact::CONTACT_METHODS[2] then

			# Associate
			contact = get_associate_contact(current_user(), params)
			if contact.nil? then
				raise "selected user (id = '#{params[:associate_id]}') not found"
			else
				@party.update_contact(contact)
				@party.tranzaction.resume()
				redirect_to(
					edit_tranzaction_path(@party.tranzaction),
					:notice => "Party identified: #{@party.contact.dba}"
				) and return
			end

		elsif @party.contact_strategy == Contact::CONTACT_METHODS[3] then

			# Publish 
			@party.update_contact(nil)
			@party.tranzaction.resume()
			redirect_to(edit_tranzaction_path(@party.tranzaction),
				:notice => "Offer will be published (made available to any user)"\
			) and return
		else
			raise "invalid party identification method"
		end
	end

end
