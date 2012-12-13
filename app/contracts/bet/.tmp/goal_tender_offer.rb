#####################################################################################
#
#
module Contracts; end

require 'state_machine'

module Contracts::Bet

	class GoalCreateOffer < Goal

		#########################################################################
		#
		# The first party is authoring a tranzaction.  Goal is to collect details
		# of the offer.  Only Contract and Goals exist until provisioning/
		# execution happens.
		#
		#########################################################################

		ARTIFACT = :OfferArtifact
		CHILDREN = [:GoalCreateOtherParty]
		FAVORITE_CHILD = true
		STEPCHILDREN = []
		AVAILABLE_TO = [:Party1]

		def execute()
		end


		def reverse_execution()
		end

		def on_expire()
			msg = "\n\nOffer creation timed out." 
			Rails.logger.info(msg)

			# This case is unique: since it's the first Goal.  We want no trace of
			# the transaction left.
			self.tranzaction.destroy()
			true
		end

		state_machine :machine_state, :initial => :s_initial do
			event :start do
				transition [:s_initial, :s_cancelled] => :OfferArtifact
			end
			before_transition [:s_initial, :s_cancelled] => :OfferArtifact do |goal, transition|
				goal.expires_at = goal.get_expiration()
				party = goal.tranzaction.model_instance(:Party1)
				goal.tranzaction.request_provisioning(party, self, :OfferArtifact)
				true
			end

			event :offer_artifact do
				transition	:OfferArtifact => :OfferArtifact,
							:if => lambda do |goal|

							end
			end
			before_transition :OfferArtifact => 
	
			inject_undo
			inject_expiration
		end
	end

	class GoalCreateOtherParty < Goal

		#########################################################################
		#
		# The first party is authoring a tranzaction.  Goal is locate the other Party.
		#
		#########################################################################

		ARTIFACT = :OfferArtifact
		#ARTIFACT = :MilestonesArtifact
		EXPIRE_ARTIFACT = :OtherPartyNotFoundArtifact 
		CHILDREN = [:GoalCreateValuables, :GoalCancelOffer]
		#CHILDREN = [:GoalCancelOffer, :GoalAcceptOffer, :GoalRejectOffer]
		FAVORITE_CHILD = true
		STEPCHILDREN = []
		AVAILABLE_TO = [:Party1]

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
			msg = "\n\nCould not identify other party." 
			Rails.logger.info(msg)
			self.tranzaction.destroy()
			true
		end

	end
	
	class GoalCreateAndReserveValuables < Goal

		#########################################################################
		#
		# The first party is authoring a tranzaction.  Goal is locate the other Party.
		#
		#########################################################################

		ARTIFACT = :MilestonesArtifact
		EXPIRE_ARTIFACT = nil
		CHILDREN = [:GoalCreateArtifacts, :GoalCancelOffer]
		CHILDREN = [:GoalCancelOffer, :GoalAcceptOffer, :GoalRejectOffer]
		FAVORITE_CHILD = true
		STEPCHILDREN = []
		AVAILABLE_TO = [:Party1]

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
			self.tranzaction.destroy()
			true
		end

	end
end
