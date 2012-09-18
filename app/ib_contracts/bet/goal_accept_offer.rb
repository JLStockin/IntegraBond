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
		CHILDREN = [:GoalDeclareWinner, :GoalMutualCancellation]
		STEPCHILDREN = [:GoalRejectOffer]

		def execute()

			offer = self.contract.model_instance(:OfferArtifact)
			raise "offer artifact not found" if offer.nil?

			p2 = nil
			if self.contract.party2.nil? then
				p2 = self.contract.namespaced_const(:Party2).new()
				p2.contract_id = self.contract.id
				p2.user = User.find_by_email(offer.party2_email)
				p2.save!
			end	

			p2_bet = nil
			if self.contract.party2_bet.nil? then
				p2_bet = self.contract.namespaced_const(:Party2Bet).new()
				p2_bet.contract_id = self.contract.id
				p2_bet.value = offer.bet_cents
				p2_bet.origin = p2
				p2_bet.disposition = p2
				p2_bet.save!
			end
			p2_bet.reserve

			p2_fees = nil
			if self.contract.party2_fees.nil? then
				p2_fees = self.contract.namespaced_const(:Party2Fees).new()
				p2_fees.contract_id = self.contract.id
				p2_fees.value = self.contract.fees() / 2
				p2_fees.origin = p2
			end
			p2_fees.disposition = self.contract.house()
			p2_fees.save!
			p2_fees.reserve

			self.contract.party1_fees.disposition = self.contract.house()
			self.contract.party1_fees.save!

			true
		end

		def reverse_execution() 
			self.contract.model_instance(:Party2Bet).release()
			self.contract.model_instance(:Party2Fees).release()
		end

		def expire()
			self.contract.reverse_and_disable_all_goals()
			true
		end

	end

	class OfferAcceptance < Artifact
		PARAMS = {\
			origin: :Party2
		}
	end

end
