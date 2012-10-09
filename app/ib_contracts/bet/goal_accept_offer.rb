#####################################################################################
#
#
require 'state_machine'
require File.dirname(__FILE__) + '/goal_declare_winner'
require File.dirname(__FILE__) + '/goal_mutual_cancellation'

module IBContracts::Bet

	class GoalAcceptOffer < Goal

		#########################################################################
		#
		# The first party has tendered an offer to the second.  The second may
		# Accept or Reject.
		#
		#########################################################################

		ARTIFACT = :OfferAcceptance
		EXPIRE_ARTIFACT = :OfferExpiration
		CHILDREN = [:GoalDeclareWinner, :GoalMutualCancellation]
		FAVORITE_CHILD = true
		STEPCHILDREN = [:GoalRejectOffer, :GoalCancelOffer]
		AVAILABLE_TO = [:Party2]
		DESCRIPTION = "Accept offer"

		def execute()

			offer = self.contract.latest_model_instance(:OfferArtifact)
			raise "offer artifact not found" if offer.nil?

			p2 = self.contract.party2

			p2_bet = self.contract.party2_bet
			if p2_bet.nil? then
				p2_bet = self.contract.namespaced_class(:Party2Bet).new()
				p2_bet.contract_id = self.contract.id
				p2_bet.value = offer.bet_cents
				p2_bet.origin = p2
				p2_bet.disposition = p2
				p2_bet.save!
			end
			p2_bet.reserve

			p2_fees = self.contract.party2_fees
			if p2_fees.nil? then
				p2_fees = self.contract.namespaced_class(:Party2Fees).new()
				p2_fees.contract_id = self.contract.id
				p2_fees.value = self.contract.fees() / 2
				p2_fees.origin = p2
			end
			p2_fees.disposition = self.contract.house()
			p2_fees.save!
			p2_fees.reserve

			self.contract.party1_fees.disposition = self.contract.house()
			self.contract.party1_fees.save!

			msg = "\n\nOffer accepted by #{p2.user.first_name} #{p2.user.last_name}."
			Rails.logger.info(msg)

			true
		end

		def reverse_execution() 
			self.contract.model_instance(:Party2Bet).release()
			self.contract.model_instance(:Party2Fees).release()
			true
		end

		def expire()
			msg0 = "Offer expired." 
			Rails.logger.info(msg0)	
			cancel_transaction()	
			#true
		end

	end

	class OfferAcceptance < Artifact
		PARAMS = {\
			origin: :Party2
		}
	end

	class OfferExpiration < Artifact
		PARAMS = {}
	end

end
