#####################################################################################
#
#
module IBContracts; end

require 'state_machine'
require File.dirname(__FILE__) + '/goal_accept_offer'
require File.dirname(__FILE__) + '/goal_reject_offer'

module IBContracts::Bet

	class GoalTenderOffer < Goal

		#########################################################################
		#
		# The first party is authoring a contract.  Goal is to tender this offer
		# to the second party.  Only Contract and Goals exist until provisioning/
		# execution happens.
		#
		#########################################################################

		ARTIFACT = :OfferArtifact
		CHILDREN = [:GoalAcceptOffer, :GoalRejectOffer]
		STEPCHILDREN = [:GoalCancelOffer]

		def execute()
			artifact = self.contract.model_instance(:OfferArtifact)

			p1 = nil
			if self.contract.party1.nil? then
				p1 = self.namespaced_const(:Party1).new()
				p1.contract_id = self.contract.id
				user1 = User.find_by_email(artifact.party1_email)
				p1.user_id = user1.id
				p1.save!
			end
			p1_bet = nil
			if self.contract.party1_bet.nil? then
				p1_bet = self.contract.namespaced_const(:Party1Bet).new()
				p1_bet.contract_id = self.contract.id
				p1_bet.value = artifact.bet_cents
				p1_bet.origin = p1
				p1_bet.disposition = p1
				p1_bet.save!
			end
			p1_bet.reserve

			p1_fees = nil
			if self.contract.party1_fees.nil? then
				p1_fees = self.contract.namespaced_const(:Party1Fees).new()
				p1_fees.contract_id = self.contract.id
				p1_fees.value = self.contract.fees()
				p1_fees.origin = p1
				p1_fees.disposition = p1
				p1_fees.save!
			end
			p1_fees.reserve

			true
		end

		def reverse_execution()
			p1_fees = self.contract.model_instance(:Party1Fees)
			p1_fees.release
			p1_bet = self.contract.model_instance(:Party1Bet)
			p1_bet.release
		end

		def expire()
			self.contract.model_instance(:GoalCancelOffer).execute(nil)
		end

	end

	class OfferArtifact < Artifact
		PARAMS = { \
			bet_cents: IBContracts::Bet::ContractBet.bond_for( :Party1 ),
			party1_email: 'user1@example.com', party2_email: 'user2@example.com',
			expirations: {\
				GoalTenderOffer:			[ nil,
					"lambda {DateTime.now.advance(minutes: 30)}" ],

				GoalCancelOffer:			[ nil,
					"lambda {DateTime.now.advance(seconds: 1770)}" ],

				GoalAcceptOffer:			[ :GoalTenderOffer,
					"lambda {|g| g.advance(hours: 24)}" ],

				GoalRejectOffer:			:never,

				GoalDeclareWinner:			[ :GoalAcceptOffer,
					"lambda {|g| g.advance(hours: 48)}" ],

				GoalMutualCancellation:		[ :GoalAcceptOffer,
					"lambda {|g| g.advance(hours: 46)}" ] \
			}\
		}

	end

end
