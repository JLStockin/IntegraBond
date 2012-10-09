#####################################################################################
#
#
module IBContracts; end

require 'state_machine'
require File.dirname(__FILE__) + '/goal_accept_offer'
require File.dirname(__FILE__) + '/goal_reject_offer'
require File.dirname(__FILE__) + '/goal_cancel_offer'

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
		EXPIRE_ARTIFACT = nil 
		CHILDREN = [:GoalCancelOffer, :GoalAcceptOffer, :GoalRejectOffer]
		FAVORITE_CHILD = true
		STEPCHILDREN = []
		AVAILABLE_TO = [:Party1]
		DESCRIPTION = "Present offer"

		def execute()
			artifact = self.contract.latest_model_instance(:OfferArtifact)

			p1 = self.contract.party1 
			if p1.nil? then
				p1 = self.contract.namespaced_class(:Party1).new()
				p1.contract_id = self.contract.id
				user1 = User.find_by_email(artifact.party1_email)
				p1.user_id = user1.id
				p1.save!
			end
			p2 = self.contract.party2
			if p2.nil? then
				p2 = self.contract.namespaced_class(:Party2).new()
				p2.contract_id = self.contract.id
				user2 = User.find_by_email(artifact.party2_email)
				p2.user_id = user2.id
				p2.save!
			end

			p1_bet = self.contract.party1_bet
			if p1_bet.nil? then
				p1_bet = self.contract.namespaced_class(:Party1Bet).new()
				p1_bet.contract_id = self.contract.id
				p1_bet.value = artifact.bet_cents
				p1_bet.origin = p1
				p1_bet.disposition = p1
				p1_bet.save!
			end
			p1_bet.reserve

			p1_fees = self.contract.party1_fees
			if p1_fees.nil? then
				p1_fees = self.contract.namespaced_class(:Party1Fees).new()
				p1_fees.contract_id = self.contract.id
				p1_fees.value = self.contract.fees()
				p1_fees.origin = p1
				p1_fees.disposition = p1
				p1_fees.save!
			end
			p1_fees.reserve

			first_party = p1.user
			second_party = p2.user
			msg = "#{first_party.first_name} #{first_party.last_name} "\
				+ "presented offer to #{second_party.first_name} #{second_party.last_name}"
			Rails.logger.info(msg)
			true
		end

		def reverse_execution()
			p1_fees = self.contract.model_instance(:Party1Fees)
			p1_fees.release
			p1_bet = self.contract.model_instance(:Party1Bet)
			p1_bet.release
		end

		def expire()
			msg = "\n\nOffer creation timed out." 
			Rails.logger.info(msg)

			# This case is unique, since it's the first Goal.  We want no trace of
			# the transaction left.
			self.contract.destroy()
			true
		end

	end

	class OfferArtifact < Artifact
		PARAMS = { \
			bet_cents: IBContracts::Bet::ContractBet.bond_for( :Party1 ),
			party1_email: 'user1@example.com', party2_email: 'user2@example.com',
			expirations: {\
				GoalTenderOffer:			[ nil,
					"lambda {DateTime.now.advance(seconds: 30)}" ],

				GoalCancelOffer:			:never,

				GoalAcceptOffer:			[ :GoalTenderOffer,
					"lambda {|g| g.advance(seconds: 10)}" ],

				GoalRejectOffer:			:never,

				GoalDeclareWinner:			[ :GoalAcceptOffer,
					"lambda {|g| g.advance(hours: 48)}" ],

				GoalMutualCancellation:		:never	
			}\
		}

	end

end
