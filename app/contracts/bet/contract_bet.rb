###################################################################################
#
#
#
module Contracts; end

module Contracts::Bet
	class ContractBet < Contract

		# Stuff specific to this contract 
		CONTRACT_NAME = "2 Party Bet"
		SUMMARY = "Bet between two parties"
		VERSION = "0.1"
		TAGS = [:default, :bet, :wager]
		CHILDREN = [:GoalTenderOffer]
		ARTIFACT = :TermsArtifact
		EXPIRATIONS = [
			:OfferExpiration,
			:BetExpiration
		]
		AUTHOR_EMAIL = "cschille@IntegraBond.com"
		PARTY_ROSTER = [:Party1, :Party2]
		VALUABLES = [
			:Party1Bet,
			:Party2Bet,
			:Party1Fees,
			:Party2Fees
		]

		# Helpers
		assoc_accessor(:Party1)
		assoc_accessor(:Party2)
		assoc_accessor(:TermsArtifact)
		assoc_accessor(:OfferExpiration)
		assoc_accessor(:BetExpiration)
		assoc_accessor(:Party1Bet)
		assoc_accessor(:Party2Bet)
		assoc_accessor(:Party1Fees)
		assoc_accessor(:Party2Fees)
		
		#
		# Setup state_machine for collecting data from tranzaction initiator
		#

		WIZARD_STEPS = [:terms, :party2, :confirm, :tendered]

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
				party2:			:terms,
				tendered:		:confirm
		]
		
		DEPENDENCIES =	[
			'contracts/bet/party1',
			'contracts/bet/party1_bet',
			'contracts/bet/goal_tender_offer'\
		]

		# Create the wizard's state_machine
		inject_page_wizard()

		def title()
			if !party1_bet.nil? and !party1_bet.value.nil? and !party1.nil? \
				and !party1.contact.nil? then
				party1_bet().value.to_s + " bet with " + party1().dba()
			else
				"Bet with a yet-to-be-determined party"
			end
		end
	
		def update_attributes(params)	

			if params.has_key?(:contracts_bet_party1_bet) then

				p = party1_bet
				p.value = Money.parse(params[:contracts_bet_party1_bet][:value])
				p.save!
			end

			if params.has_key?(:contracts_bet_party2_bet) then
				party2_bet.value = Money.parse(params[:contracts_bet_party2_bet][:value])
				party2_bet.save!
			end

			if params.has_key?(:contracts_bet_party1_fees) then
				party1_fees.value = Money.parse(params[:contracts_bet_party1_fees][:value])
				party1_fees.save!
			end

			if params.has_key?(:contracts_bet_party2_fees) then
				party2_fees.value = Money.parse(params[:contracts_bet_party2_fees][:value])
				party2_fees.save!
			end

			if params.has_key?(:contracts_bet_terms_artifact) then
				terms_artifact.mass_assign_params(params[:contracts_bet_terms_artifact])
				terms_artifact.save!
			end

			if params.has_key?(:contracts_bet_offer_expiration) then
				offer_expiration.offset = (params[:contracts_bet_offer_expiration][:offset])
				offer_expiration.update_attributes(params[:contracts_bet_offer_expiration])
				offer_expiration.save!
			end

			if params.has_key?(:contracts_bet_bet_expiration) then
				bet_expiration.update_attributes(params[:contracts_bet_bet_expiration])
				bet_expiration.save!
			end

		end

	end

	ContractBet.register_dependencies()

end # Contracts::Bet
