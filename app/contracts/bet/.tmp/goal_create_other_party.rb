#####################################################################################
#
#
module Contracts; end

require 'state_machine'
require File.dirname(__FILE__) + '/goal_accept_offer'
require File.dirname(__FILE__) + '/goal_reject_offer'
require File.dirname(__FILE__) + '/goal_cancel_offer'

module Contracts::Bet

	class GoalCreateOtherParty < Goal

		#########################################################################
		#
		# The first party is authoring a tranzaction.  Goal is locate the other Party.
		#
		#########################################################################

		ARTIFACT = :OfferArtifact
		EXPIRE_ARTIFACT = nil
		CHILDREN = [:GoalCancelOffer]
		CHILDREN = [:GoalCancelOffer, :GoalAcceptOffer, :GoalRejectOffer]
		FAVORITE_CHILD = true
		STEPCHILDREN = []
		AVAILABLE_TO = [:Party1]
		DESCRIPTION = "Create an offer"

		def execute()
			p2 = create_party(	:Party2,
								offer_artifact().party2_contact_type,
								offer_artifact().party2_contact_data
			)
			!p2.nil? and self.tranzaction.resolve_contact(p2) and return true

			PartyContactUnresolved.push_to_party( Party1: party1(), Party2: p2 )
			return false
		end
			!p2.nil	
			v1, v2 = nil, nil
			unless p1.nil? then
				v1 = create_valuable(	:Party1Bet,
										offer_artifact.party1_bet,
										p1,
										p1
				)
				v2 = create_valuable(	:Party1Fees,
										offer_artifact.party1_fees,
										p1,
										p1
				)
			end
		end

		def reverse_execution()
		end

		def on_expire()
			msg = "\n\nOffer creation timed out." 
			Rails.logger.info(msg)

			# This case is unique, since it's the first Goal.  We want no trace of
			# the transaction left.
			self.tranzaction.destroy()
			true
		end

	end
	
	class PartyContactUnresolved

	end

end
