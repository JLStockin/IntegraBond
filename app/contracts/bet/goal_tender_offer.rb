#####################################################################################
#
# Goals for ContractBet
#
module Contracts::Bet

	#########################################################################
	#
	# Current thinking: this Goal should never call request_provision(); it's
	# created by the Tranzaction.
	#
	#########################################################################
	class GoalTenderOffer < Goal

		ARTIFACT = :OfferPresentedArtifact 
		CHILDREN = [:GoalAcceptOffer, :GoalCancelOffer]
		FAVORITE_CHILD = true
		STEPCHILDREN = []
		AVAILABLE_TO = [:Party1]
		EXPIRATION = :OtherPartyNotFoundExpiration
		DESCRIPTION = "Present offer"

		def execute(artifact)
			self.tranzaction.party1_bet.disposition = self.tranzaction.party1
			self.tranzaction.party1_bet.reserve()
			self.tranzaction.party1_fees.disposition = self.tranzaction.house()
			self.tranzaction.party1_fees.reserve()

			self.tranzaction.party2_bet.value = self.tranzaction.party1_bet.value 
			self.tranzaction.party2_bet.save!
			self.tranzaction.party2_fees.value = self.tranzaction.party1_fees.value 
			self.tranzaction.party2_fees.save!

		end

		def reverse_execution()
			self.tranzaction.party1_bet.disposition = party1
			self.tranzaction.party1_bet.release
			self.tranzaction.party1_fees.disposition = party1
			self.tranzaction.party1_fees.release
		end

		def on_expire(artifact)
			msg = "Offer creation timed out (or the other party couldn't be located or didn't respond)." 
			self.tranzaction.flash_party(self.tranzaction.party1, msg)
			self.tranzaction.flash_party(self.tranzaction.party2, msg)
			true
		end
	end

	Artifact # artifact.rb defines ProvisionableArtifact

	class OfferPresentedArtifact < ProvisionableArtifact
		PARAMS = {}
		IMMUTABLE = true
	end

	class TermsArtifact < ProvisionableArtifact
		PARAMS = {
			:text => "PARTY1 bets PARTY2 BET_AMOUNT that PARTY2 will like IntegraBond.\n\nPARTY2 has OFFER_EXPIRATION to accept.  PARTY1 and PARTY2 have BET_EXPIRATION to declare the winner.  Both parties must declare the same winner.  In the event of disagreement, the outcome will be considered in dispute.  Disputes will be resolved through binding arbitration; arbitration costs are born by the loser.\n\nIn the event that one party responds in time, but another does not, the lone respondant's answer will determine the outcome.  If both parties fail to respond in time, the bet will be cancelled."
		}
		IMMUTABLE = true
	end

	class OtherPartyNotFoundExpiration < Expiration
		DEFAULT_OFFSET = 30
		DEFAULT_OFFSET_UNITS = :seconds
		BASIS_TYPE = :OfferAcceptedArtifact
		ARTIFACT = :OtherPartyNotFoundArtifact
	end

	class OtherPartyNotFoundArtifact < ExpiringArtifact
	end

	#
	# GoalCancelOffer
	#
	#
	class GoalCancelOffer < Goal
		ARTIFACT = :OfferWithdrawnArtifact 
		CHILDREN = nil
		FAVORITE_CHILD = false
		STEP_CHILDREN = nil 
		AVAILABLE_TO = [:Party1]
		DESCRIPTION = "Withdraw offer to bet"

		def execute(artifact)
			self.cancel_tranzaction()
		end

		def reverse_execution()
		end
	end

	class OfferWithdrawnArtifact < ProvisionableArtifact
		PARAMS = {} 
		IMMUTABLE = true
	end

	#########################################################################
	#
	# The first party has tendered an offer to the second.
	# Success path.
	#
	#########################################################################
	class GoalAcceptOffer < Goal

		ARTIFACT = :OfferAcceptedArtifact
		EXPIRATION = :OfferExpiration
		CHILDREN = [:GoalDeclareWinner, :GoalMutualCancellationArtifact]
		FAVORITE_CHILD = true
		STEPCHILDREN = [:GoalRejectOffer, :GoalCancelOffer]
		AVAILABLE_TO = [:Party2]
		DESCRIPTION = "Accept offer"

		def execute(artifact)

			p2 = self.tranzaction.party2

			p2_bet = self.tranzaction.party2_bet
			unless p2_bet.nil? then
				p2_bet.origin = p2
				p2_bet.disposition = p2
				p2_bet.save!
				p2_bet.reserve
			end

			p2_fees = self.tranzaction.party2_fees
			unless p2_fees.nil? then
				p2_fees.origin = p2
				p2_fees.disposition = self.tranzaction.house()
				p2_fees.save!
				p2_fees.reserve
			end

			self.tranzaction.party1_fees.disposition = self.tranzaction.house()
			self.tranzaction.party1_fees.save!

			msg = "Offer accepted by #{p2.user_identifier}"
			self.tranzaction.flash_party(p2, msg)
			true
		end

		def reverse_execution() 
			self.tranzaction.model_instance(:Party2Bet).release()
			self.tranzaction.model_instance(:Party2Fees).release()
			true
		end

		def on_expire(artifact)
			msg = "Offer expired; releaseing funds" 
			self.tranzaction.flash_party(p1, msg)
			self.tranzaction.flash_party(p2, msg)
			cancel_transaction()	
			true
		end

	end

	class OfferAcceptedArtifact < ProvisionableArtifact
		PARAMS = {\
			origin: :Party2
		}
		IMMUTABLE = true
	end


	#########################################################################
	#
	# The first party has tendered an offer to the second.
	# Failure paths.
	#
	#########################################################################
	class GoalRejectOffer < Goal

		ARTIFACT = :OfferRejectedArtifact 
		CHILDREN = []
		FAVORITE_CHILD = false 
		STEPCHILDREN = [:GoalAcceptOffer, :GoalCancelOffer]
		AVAILABLE_TO = [:Party2]
		DESCRIPTION = "Reject offer"

		def provision_needed?()
			return true
			#if party1.resolved?
		end

		def execute(artifact)
			party1 = self.tranzaction.party1
			party2 = self.tranzaction.party2
			msg1 = "Offer rejected by #{party2.user_identifier}."\
				+ "\nTransaction cancelled."
			msg2 = "Transaction cancelled."
			self.tranzaction.flash_party(party1, msg1)
			self.tranzaction.flash_party(party2, msg2)

			cancel_transaction()
		end

		def reverse_execution()
			true
		end

		def on_expire(artifact)
			# This goal should never time out.
			false
		end
	end

	class OfferRejectedArtifact < ProvisionableArtifact
		PARAMS = {}
		IMMUTABLE = true
	end

	class OfferExpiration < Expiration
		DEFAULT_OFFSET = 24 
		DEFAULT_OFFSET_UNITS = :hours
		BASIS_TYPE = :OfferPresentedArtifact
		ARTIFACT = :OfferExpiredArtifact
	end

	class OfferExpiredArtifact < ExpiringArtifact
	end

	#########################################################################
	#
	# The Tranzaction is in play, but one of the Parties wants out.  Second
	# must agree, or the Tranzaction continues as usual.
	#
	#########################################################################
	class GoalMutualCancellationArtifact < Goal

		ARTIFACT = :MutualCancellationArtifact
		EXPIRATION = nil 
		CHILDREN = []
		FAVORITE_CHILD = false 
		STEPCHILDREN = [:GoalDeclareWinner]
		AVAILABLE_TO = [:Party1, :Party2]
		DESCRIPTION = "Cancel (with other party's approval)"

		def execute()
			
			have_cancellation = false

			requests = self.tranzaction.model_instances(:MutualCancellationArtifact)
			confirmations = {}
			confirmations[:Party1] = [nil, false]
			confirmations[:Party2] = [nil, false]

			requests.each do |request|
				confirmations[:Party1] = [request, true] \
					if request.origin == :Party1 and request.counted == false
				confirmations[:Party2] = [request, true] \
					if request.origin == :Party2 and request.counted == false
			end

			requester = tranzaction.latest_model_instance(:MutualCancellationArtifact).origin
			requester = tranzaction.model_instance(requester).contact.user
			msg = "\n\n#{requester.first_name} #{requester.last_name} has requested cancellation."
			Rails.logger.info(msg)

			if confirmations[:Party1][1] and confirmations[:Party2][1] then 

				# We have the consent of both.  Create an Artifact to that effect
				# and disable transaction. 
				# Also, mark all three artifacts as counted
				cancellation = self.tranzaction.namespaced_class(:MutualCancellationArtifact).new()
				cancellation.tranzaction_id = self.tranzaction_id
				cancellation.goal_id = self.id
				cancellation.origin = :PartyAdmin
				cancellation.counted = true
				cancellation.save!

				confirmations[:Party1][0].counted = true
				confirmations[:Party1][0].save!
				confirmations[:Party2][0].counted = true
				confirmations[:Party2][0].save!

				cancel_transaction()

				msg2 = "Transaction cancelled by mutual agreement."
				Rails.logger.info(msg2)

				have_cancellation = true
			else
				self.machine_state = :s_provisioning
				self.save!
				self.start
				have_cancellation = false 
			end

			have_cancellation	
		end

		def reverse_execution()
			true
		end

		def on_expire()
			# This goal should never time out 
			false	
		end
	end

	class MutualCancellationArtifact < ProvisionableArtifact
		# Origin should be a Symbol, like ':Party1'
		PARAMS = {\
			origin: :Party1,
			counted: false
		}
	end

	#########################################################################
	#
	# Offer was accepted; bet is in play. 
	# Success and failure paths.
	#
	#########################################################################
	class GoalDeclareWinner < Goal

		ARTIFACT = :OutcomeAssertionArtifact
		EXPIRATION = :BetExpiration
		CHILDREN = []	# TODO add a GoalDispute, and implement reverse_execution
		FAVORITE_CHILD = true
		STEPCHILDREN = [:GoalMutualCancellationArtifact]
		AVAILABLE_TO = [:Party1, :Party2]
		DESCRIPTION = "Indicate the Winner"

		def execute(artifact)
			have_a_winner = false
			artifact = self.tranzaction.latest_model_instance(:OutcomeAssertionArtifact)

			if (	artifact.winner == other_party(artifact.origin) and\
					artifact.counted == false
			) then
				# We have a winner.
				
				# Create a new Artifact noting that and close transaction.	
				result = ::Contracts::Bet::OutcomeAssertionArtifact.new()
				result.tranzaction_id = self.tranzaction_id
				result.mass_assign_params( origin: :PartyAdmin, winner: artifact.winner)

				# Mark all the artifacts that we used to establish this conclusion.
				artifact.counted = true
				artifact.save!
				result.counted = true
				result.goal = self 
				result.save!

				# Dispense bet monies
				to_release = (result.winner == :Party1)\
					? self.tranzaction.party1_bet \
					: self.tranzaction.party2_bet 
				to_transfer = (result.winner == :Party1)\
					? self.tranzaction.party2_bet : self.tranzaction.party1_bet 

				to_transfer.disposition = to_release.origin 
				to_release.release
				to_transfer.transfer

				# Dispense fees.  Winner pays the house.
				to_release = (result.winner == :Party1)\
					? self.tranzaction.party2_fees\
					: self.tranzaction.party1_fees
				to_transfer = (result.winner == :Party1)\
					? self.tranzaction.party1_fees\
					: self.tranzaction.party2_fees 
				to_transfer.disposition = self.tranzaction.house() 
				to_release.release
				to_transfer.transfer

				# We're done.  Disable all goals.
				self.tranzaction.disable_active_goals(self)

				user = tranzaction.model_instance(artifact.winner).contact.user
				msg0 = "\n\n#{user.first_name} #{user.last_name} wins."
				Rails.logger.info(msg0)
				msg1 = "Transaction closed."
				Rails.logger.info(msg1)

				have_a_winner = true
			else
				self.machine_state = :s_provisioning
				self.save!
				self.start

				origin = tranzaction.model_instance(artifact.origin).contact.user
				winner = tranzaction.model_instance(artifact.winner).contact.user
				msg = "#{origin.first_name} #{origin.last_name} " \
					+ "asserts that #{winner.first_name} #{winner.last_name} won."
				Rails.logger.info(msg)

				have_a_winner = false 
			end

			have_a_winner	
		end

		# TODO: implement 
		def reverse_execution()
			true
		end

		def on_expire(artifact)
			msg0 = "Transaction expired." 
			Rails.logger.info(msg0)
			cancel_transaction()
			true
		end

		private
			def other_party(party)
				party == :Party1 ? :Party2 : :Party1
			end
	end

	class OutcomeAssertionArtifact < ProvisionableArtifact
		PARAMS = {origin: nil, winner: nil}
		IMMUTABLE = true
	end

	class BetExpiration < Expiration
		DEFAULT_OFFSET = 48 
		DEFAULT_OFFSET_UNITS = :hours
		BASIS_TYPE = :OfferAcceptedArtifact
		ARTIFACT = :BetExpirationArtifact
	end

	class BetExpirationArtifact < ExpiringArtifact
	end
end
