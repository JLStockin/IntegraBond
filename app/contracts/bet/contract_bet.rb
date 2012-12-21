###################################################################################
#
#
#
module Contracts; end

module Contracts::Bet
	class ContractBet < Contract

		# Stuff specific to this contract 
		CONTRACT_NAME = "2 Party Bet"
		VERSION = "0.1"
		TAGS = [:default, :bet, :wager]
		CHILDREN = [:GoalTenderOffer]
		ARTIFACT = :TermsArtifact
		EXPIRATIONS = [ \
			:OtherPartyNotFoundExpiration,
			:OfferExpiration,
			:BetExpiration\
		]
		AUTHOR_EMAIL = "cschille@IntegraBond.com"
		PARTY_ROSTER = [:Party1, :Party2]
		VALUABLES = [ \
			:Party1Bet,
			:Party2Bet,
			:Party1Fees,
			:Party2Fees\
		]

		# Helpers
		assoc_accessor(:Party1)
		assoc_accessor(:Party2)
		assoc_accessor(:TermsArtifact)
		assoc_accessor(:OfferExpiration)
		assoc_accessor(:BetExpiration)
		assoc_accessor(:OtherPartyNotFoundExpiration)
		assoc_accessor(:Party1Bet)
		assoc_accessor(:Party2Bet)
		assoc_accessor(:Party1Fees)
		assoc_accessor(:Party2Fees)
		
		#
		# Setup state_machine for collecting data from tranzaction initiator
		#

		WIZARD_STEPS = [:terms, { :party2 => :party_locater }, :confirm, :tendered]

		# Array of Hashes
		PAGE_OBJECTS = \
		{
			:terms				=> [:Party1Bet, :TermsArtifact,\
									:OfferExpiration, :BetExpiration],
			:party2				=> [:Party2],
			:confirm			=> nil,
			:tendered			=> nil
		}

		# Note that there isn't a transition between :party2 and :confirm  --
		# This is handled by the parties_controller
		#
		FORWARD_TRANSITIONS = [
			{
				on: :next_step,
					terms:			:party2,
					confirm:		:tendered
			},
			{
				on: :resume,
					party2:			:confirm
			}
		]

		REVERSE_TRANSITIONS = [
			on: :previous_step,
				confirm:		:party2,
				party2:			:terms
		]
		
		DEPENDENCIES =	[
			'contracts/bet/party1',
			'contracts/bet/party1_bet',
			'contracts/bet/goal_tender_offer'\
		]

		# Create the wizard's state_machine
		inject_page_wizard()

		def title()
			if !party1_bet.nil? and !party1_bet.value.nil? and !party1.nil? and !party1.contact.nil?
				party1_bet().value + " bet with " + party1().contact 
			else
				"Bet with a yet-to-be-determined party"
			end
		end
	
		def update_attributes(params)	
			if params.has_key?(:contracts_bet_party1_bet) then
				party1_bet.update_attributes(params[:contracts_bet_party1_bet])
				party1_bet.save!
			end

			if params.has_key?(:contracts_bet_terms_artifact) then
				terms_artifact.mass_assign_params(params[:contracts_bet_terms_artifact])
				terms_artifact.save!
			end

			if params.has_key?(:contracts_bet_offer_expiration) then
				offer_expiration.update_attributes(params[:contracts_bet_offer_expiration])
				offer_expiration.save!
			end

			if params.has_key?(:contracts_bet_bet_expiration) then
				bet_expiration.update_attributes(params[:contracts_bet_bet_expiration])
				bet_expiration.save!
			end

			if params.has_key?(:party2) then
				if (params[:contact_strategy] == ModelDescriptor::CONTACT_METHODS[0]) then
					klass = Contact.subclasses.key(\
						params[:contact][:contact_type_index].to_i\
					).to_s.constantize
					party2.contact = klass.create!(:contact_data => params[:contact][:contact_data])
					party2.save!
					new_contacts = Contact.get_contact(
						party2.contact.class,
						party2.contact.contact_data
					)
					if new_contacts.nil? then
						self.user_not_found(party.contact)
					elsif new_contacts.count > 1 then
						self.disambiguate(party.contact)
					else
						self.next_step
					end
				end
			end
			if params.has_key?(:contact) then
				if (params[:contact_strategy] == 1) then
					klass = Contact.subclasses.key(\
						params[:contact][:contact_type_index].to_i\
					).to_s.constantize
					party2.contact = klass.create!(:contact_data => params[:contact][:contact_data])
					party2.save!
				end
			end
		end

		def configuring_party?
			self.class::PARTY_ROSTER.include? self.wizard_step.camelize.to_sym
		end
	end

	ContractBet.register_dependencies()

end # Contracts::Bet
