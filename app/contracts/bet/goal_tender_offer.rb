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
		EXPIRATION = nil
		CHILDREN = [:GoalAcceptOffer, :GoalRejectOffer, :GoalCancelOffer]
		FAVORITE_CHILD = true
		STEPCHILDREN = []
		AVAILABLE_TO = [:Party1]
		DESCRIPTION = "Present offer"
		SELF_PROVISION = true 

		def execute(artifact)
			begin
				p1_bet = self.tranzaction.party1_bet
				p1_bet.disposition = self.tranzaction.party1
				p1_bet.save!
				p1_bet.reserve()

				p1_fees = self.tranzaction.party1_fees 
				p1_fees.disposition = self.tranzaction.house()
				p1_fees.reserve()
			rescue InsufficientFundsError
				artifact.destroy()
				raise # Propagate error to controller 
			end
		end

		def reverse_execution()
			p1_bet = self.tranzaction.party1_bet
			p1_bet.release
			p1_bet.disposition = self.tranzaction.party1
			p1_bet.save!

			p1_fees = self.tranzaction.party1_fees
			p1_fees.release
			p1_fees.disposition = self.tranzaction.party1
			p1_fees.save!
		end

		def on_expire(artifact)
			msg = "Offer creation timed out (or the other party couldn't be located "\
				+ "or didn't respond)." 
			self.tranzaction.flash_party(self.tranzaction.party1, msg)
			true
		end
	end

	Artifact # artifact.rb defines ProvisionableArtifact

	class TermsArtifact < ProvisionableArtifact
		PARAMS = {
			:text => "PARTY1 bets PARTY2 BET_AMOUNT that PARTY2 will like IntegraBond.\n\nPARTY2 has OFFER_EXPIRATION to accept.  PARTY1 and PARTY2 have BET_EXPIRATION to declare the winner.  Both parties must declare the same winner.  In the event of disagreement, the outcome will be considered in dispute.  Disputes will be resolved through binding arbitration; arbitration costs are born by the loser.\n\nIn the event that one party responds in time, but another does not, the lone respondant's answer will determine the outcome.  If both parties fail to respond in time, the bet will be cancelled."
		}
		IMMUTABLE = true
	end

	class OfferPresentedArtifact < ProvisionableArtifact
		PARAMS = {}
		IMMUTABLE = true
	end

	#
	# GoalCancelOffer
	#
	#
	class GoalCancelOffer < Goal
		ARTIFACT = :OfferWithdrawnArtifact 
		EXPIRATION = nil
		CHILDREN = nil
		FAVORITE_CHILD = false
		STEPCHILDREN = [] 
		AVAILABLE_TO = [:Party1]
		DESCRIPTION = "Withdraw offer to bet"
		SELF_PROVISION = false

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
		CHILDREN = [:GoalDeclareWinner, :GoalMutualCancellation]
		FAVORITE_CHILD = true
		STEPCHILDREN = [:GoalRejectOffer, :GoalCancelOffer]
		AVAILABLE_TO = [:Party2]
		DESCRIPTION = "Accept offer"

		def execute(artifact)
			retval = true 
			p2 = self.tranzaction.party2
			p2_bet = self.tranzaction.party2_bet
			p1 = self.tranzaction.party1
			begin
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
			rescue InsufficientFundsError => error
				artifact.destroy()
				retval = false
				msg = "Insufficient funds to make offer -- error '#{error}')."
				msg += "  (Did you forget to deposit money in your account?)"
				self.tranzaction.flash_party(p2, msg)
			end

			if retval then
				msg = "Offer accepted by #{p2.user_identifier}"
				self.tranzaction.flash_party(p1, msg)
				msg = "You have accepted the offer"
				self.tranzaction.flash_party(p2, msg)
			end

			retval	
		end

		def reverse_execution() 
			self.tranzaction.model_instance(:Party2Bet).release()
			self.tranzaction.model_instance(:Party2Fees).release()
			true
		end

		def on_expire(artifact)
			msg = "Offer expired; releasing funds" 
			p1 = self.tranzaction.party1
			p2 = self.tranzaction.party2
			self.tranzaction.flash_party(p1, msg)
			self.tranzaction.flash_party(p2, msg)
			cancel_tranzaction()	
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
		EXPIRATION = nil
		CHILDREN = []
		FAVORITE_CHILD = false 
		STEPCHILDREN = [:GoalAcceptOffer, :GoalCancelOffer]
		AVAILABLE_TO = [:Party2]
		DESCRIPTION = "Reject offer"
		SELF_PROVISION = false

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

			cancel_tranzaction()
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
	class GoalMutualCancellation < Goal

		ARTIFACT = :MutualCancellationArtifact
		EXPIRATION = nil 
		CHILDREN = []
		FAVORITE_CHILD = false 
		STEPCHILDREN = [:GoalDeclareWinner]
		AVAILABLE_TO = [:Party1, :Party2]
		DESCRIPTION = "Cancel (with other party's approval)"
		SELF_PROVISION = false

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

				cancel_tranzaction()

				msg2 = "Transaction cancelled by mutual agreement."
				Rails.logger.info(msg2)

				have_cancellation = true
			else
				self.state = :s_provisioning
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
		STEPCHILDREN = [:GoalMutualCancellation]
		AVAILABLE_TO = [:Party1, :Party2]
		DESCRIPTION = "Indicate the Winner"

		def execute(artifact)
			origin, winner = winner(artifact)
			if !(winner.nil?) then
				
				# Create new Artifact with origin administrator 
				new_artifact = OutcomeAssertionArtifact.new()
				new_artifact.tranzaction = self.tranzaction
				new_artifact.winner = winner
				new_artifact.origin = :PartyAdmin
				new_artifact.save!

				# Dispense bet monies
				to_release = (winner == :Party1)\
					? self.tranzaction.party1_bet \
					: self.tranzaction.party2_bet 
				to_transfer = (winner == :Party1)\
					? self.tranzaction.party2_bet : self.tranzaction.party1_bet 

				to_transfer.disposition = to_release.origin 
				to_release.release
				to_transfer.transfer

				# Dispense fees.  Winner pays the house.
				to_release = (winner == :Party1)\
					? self.tranzaction.party2_fees\
					: self.tranzaction.party1_fees
				to_transfer = (winner == :Party1)\
					? self.tranzaction.party1_fees\
					: self.tranzaction.party2_fees 
				to_transfer.disposition = self.tranzaction.house() 
				to_release.release
				to_transfer.transfer


				# We're done.  Disable all goals.
				self.tranzaction.disable_active_goals(self)

				user = tranzaction.model_instance(artifact.winner).contact.user
				msg = "#{user.first_name} #{user.last_name} wins.  Transaction closed."
				p1 = self.tranzaction.party1
				p2 = self.tranzaction.party2
				self.tranzaction.flash_party(p1, msg)
				self.tranzaction.flash_party(p2, msg)
			else
				# Restart this Goal
				self.state = :s_initial
				self.save!
				self.start
				origin = tranzaction.model_instance(origin.to_sym).contact.user
				msg = "#{origin.first_name} #{origin.last_name} " \
					+ "asserts that #{origin.first_name} #{origin.last_name} won."
				p1 = self.tranzaction.party1
				p2 = self.tranzaction.party2
				self.tranzaction.flash_party(p1, msg)
				self.tranzaction.flash_party(p2, msg)
			end

			!winner.nil?	
		end

		# TODO: implement 
		def reverse_execution()
			true
		end

		def on_expire(artifact)
			msg0 = "Transaction expired." 
			Rails.logger.info(msg0)
			cancel_tranzaction()
			true
		end

		private
			def winner(artifact)
				return (artifact.origin == :Party1) ^ (artifact.winner == :Party1)\
					? [artifact.origin, artifact.winner]\
					: [artifact.origin, nil]
			end
	end

	class OutcomeAssertionArtifact < ProvisionableArtifact
		PARAMS = {origin: nil, winner: nil}
		IMMUTABLE = true
		before_save do
			self.origin = self.origin.to_sym unless self.origin.nil?
			self.winner = self.winner.to_sym unless self.winner.nil?
		end
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
