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
		CHILDREN = [:GoalAcceptOffer, :GoalRejectOffer, :GoalWithdrawOffer]
		FAVORITE_CHILD = true
		STEPCHILDREN = []
		AVAILABLE_TO = [:Party1]
		DESCRIPTION = "Present offer"
		SELF_PROVISION = true 
		STUBBORN = false 

		def execute(artifact)
			begin
				p1_bet = self.tranzaction.party1_bet
				p1_bet.disposition = self.tranzaction.party1
				p1_bet.save!
				p1_bet.reserve!()

				p1_fees = self.tranzaction.party1_fees 
				p1_fees.disposition = self.tranzaction.house()
				p1_fees.reserve!()
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
		before_save do
			self.origin = self.tranzaction.symbol_to_party(:Party1)
		end

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				self.originator?(user) ? :required : :waiting
			)
		end
	end

	class OfferPresentedArtifact < ProvisionableArtifact
		PARAMS = {}
		IMMUTABLE = true
		# needed because of Goal auto-provision
		before_save do
			self.origin = self.tranzaction.symbol_to_party(:Party1)
		end

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
			desc = substitute_user(
				desc, user,
				self.origin, '%ORIGIN%'
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				self.originator?(user) ? :waiting : :required 
			)
		end

	end

	#
	# GoalWithdrawOffer
	#
	#
	class GoalWithdrawOffer < Goal
		ARTIFACT = :OfferWithdrawnArtifact 
		EXPIRATION = nil
		CHILDREN = nil
		FAVORITE_CHILD = false
		STEPCHILDREN = [] 
		AVAILABLE_TO = [:Party1]
		DESCRIPTION = "Withdraw offer to bet"
		SELF_PROVISION = false 
		STUBBORN = false 

		def execute(artifact)
			self.cancel_tranzaction()
		end

		def reverse_execution()
		end
	end

	class OfferWithdrawnArtifact < ProvisionableArtifact
		before_save do
			self.origin = self.tranzaction.symbol_to_party(:Party1)
		end
		PARAMS = {} 
		IMMUTABLE = true

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
			desc = substitute_user(
				desc, user, self.origin, '%ORIGIN%'
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				:default
			)
		end
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
		STEPCHILDREN = [:GoalRejectOffer, :GoalWithdrawOffer]
		AVAILABLE_TO = [:Party2]
		DESCRIPTION = "Accept offer"
		SELF_PROVISION = false
		STUBBORN = false 

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
		before_save do
			self.origin = self.tranzaction.symbol_to_party(:Party2)
		end
		PARAMS = {}
		IMMUTABLE = true

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
			desc = substitute_user(
				desc, user,
				self.origin, '%ORIGIN%'
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				self.originator?(user) ? :waiting : :requested
			)
		end
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
		STEPCHILDREN = [:GoalAcceptOffer, :GoalWithdrawOffer]
		AVAILABLE_TO = [:Party2]
		DESCRIPTION = "Reject offer"
		SELF_PROVISION = false
		STUBBORN = false 

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
		before_save do
			self.origin = self.tranzaction.symbol_to_party(:Party2)
		end
		PARAMS = {}
		IMMUTABLE = true

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
			desc = substitute_user(
				desc, user,
				self.origin, '%ORIGIN%'
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				:default
			)
			desc = substitute_user(
				desc, user,
				self.origin, '%ORIGIN%'
			)
		end
	end

	class OfferExpiration < Expiration
		DEFAULT_OFFSET = 24 
		DEFAULT_OFFSET_UNITS = :hours
		BASIS_TYPE = :OfferPresentedArtifact
		ARTIFACT = :OfferExpiredArtifact
	end

	class OfferExpiredArtifact < ExpiringArtifact

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				:default
			)
		end
	end

	#########################################################################
	#
	# The Tranzaction is in play, but one of the Parties wants out.  Second
	# must agree, or the Tranzaction continues as usual.
	#
	#########################################################################
	class GoalMutualCancellation < Goal

		ARTIFACT = :MutualCancellationRequestArtifact
		EXPIRATION = nil 
		CHILDREN = []
		FAVORITE_CHILD = false 
		STEPCHILDREN = [:GoalDeclareWinner]
		AVAILABLE_TO = [:Party1, :Party2]
		DESCRIPTION = "Cancel (with other party's approval)"
		SELF_PROVISION = false
		STUBBORN = true

		def execute(artifact)
			
			have_cancellation = false

			requests = self.tranzaction.model_instances(:MutualCancellationRequestArtifact)
			confirmations = {}
			confirmations[:Party1] = false
			confirmations[:Party2] = false
			confirmations[:PartyAdmin] = false

			requests.each do |request|
				origin_sym = request.origin.to_symbol()
				confirmations[origin_sym] = true unless request.counted
			end

			origin_sym = self.tranzaction.latest_model_instance(:MutualCancellationRequestArtifact)\
				.to_symbol()
			requester = ((origin_sym == :Party1)\
				? self.tranzaction.party1\
				: self.tranzaction.party2
			).user

			msg = "\n\n#{requester.first_name} #{requester.last_name} has requested cancellation."

			p1 = self.tranzaction.party1
			p2 = self.tranzaction.party2

			if (confirmations[:Party1] and confirmations[:Party2]) then 
			
				# We have the consent of both.  Create an Artifact (on the fly) to that effect
				# and disable transaction. 
				cancellation = self.tranzaction.namespaced_class(:MutualCancellationArtifact).new()
				cancellation.tranzaction_id = self.tranzaction_id
				cancellation.goal_id = self.id
				cancellation.save!
				cancel_tranzaction()

				msg2 = "Transaction cancelled by mutual agreement."
				self.tranzaction.flash_party(p1, msg2)
				self.tranzaction.flash_party(p2, msg2)

				# Mark all these as 'counted' in case this tranzaction is resurrected
				requests.each do |request|
					request.counted = true
				end

				have_cancellation = true
			else
				have_cancellation = false 
				self.tranzaction.flash_party(p1, msg)
				self.tranzaction.flash_party(p2, msg)
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

	class MutualCancellationRequestArtifact < ProvisionableArtifact
		PARAMS = {\
			counted: false
		}

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
			desc = substitute_user(
				desc, user,
				self.origin, '%ORIGIN%'
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				:default
			)
			desc = substitute_user(
				desc, user,
				self.origin, '%ORIGIN%'
			)
		end
	end

	class MutualCancellationArtifact < ProvisionableArtifact
		before_save do
			self.origin = self.tranzaction.house
		end
		PARAMS = {}

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				:default
			)
		end
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
		SELF_PROVISION = false
		STUBBORN = true 

		def execute(artifact)

			have_a_winner = artifact.have_a_winner?
			if (have_a_winner) then
				
				winner_sym = artifact.winner.to_sym

				# Create new Artifact with origin administrator 
				new_artifact = OutcomeFinalArtifact.new()
				new_artifact.goal = self
				new_artifact.tranzaction = self.tranzaction
				new_artifact.winner = winner_sym 
				new_artifact.origin = self.tranzaction.house() 
				new_artifact.save!

				# Dispense bet monies
				to_release = (winner_sym == :Party1)\
					? self.tranzaction.party1_bet \
					: self.tranzaction.party2_bet 
				to_transfer = (winner_sym == :Party1)\
					? self.tranzaction.party2_bet : self.tranzaction.party1_bet 

				to_transfer.disposition = to_release.origin 
				to_release.release
				to_transfer.transfer

				# Dispense fees.  Winner pays the house.
				to_release = (winner_sym == :Party1)\
					? self.tranzaction.party2_fees\
					: self.tranzaction.party1_fees
				to_transfer = (winner_sym == :Party1)\
					? self.tranzaction.party1_fees\
					: self.tranzaction.party2_fees 
				to_transfer.disposition = self.tranzaction.house() 
				to_release.release
				to_transfer.transfer


				# We're done.  Disable all goals.
				self.tranzaction.disable_active_goals(self)

				user = self.tranzaction.symbol_to_party(artifact.winner).user
				msg = "#{user.first_name} #{user.last_name} wins.  Transaction closed."
				p1 = self.tranzaction.party1
				p2 = self.tranzaction.party2
				self.tranzaction.flash_party(p1, msg)
				self.tranzaction.flash_party(p2, msg)
			else
				# Restart this Goal
				msg = "#{artifact.origin.user.first_name} #{artifact.origin.user.last_name} " \
					+ "asserts that #{artifact.origin.user.first_name} "\
					+ "#{artifact.origin.user.last_name} won."
				p1 = self.tranzaction.party1
				p2 = self.tranzaction.party2
				self.tranzaction.flash_party(p1, msg)
				self.tranzaction.flash_party(p2, msg)
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
			cancel_tranzaction()
			true
		end

	end

	class OutcomeAssertionArtifact < ProvisionableArtifact
		PARAMS = {winner: nil}
		IMMUTABLE = true

		def subclass_init(instance, party)
			self.winner = party.to_symbol()
		end

		def have_a_winner?()
			op = nil
			if self.arrogant?() then
				op = :modest?	
			else
				op = :arrogant?
			end

			type = self.class.to_s
			artifacts = self.tranzaction.artifacts.where{self.type == type} 
			artifacts.each do |artifact|
				return true if artifact.send(op)
			end
			false
		end

		def modest?()
			outcome = (
				(self.origin.to_symbol() == :Party1)\
				^\
				(self.winner.to_sym == :Party1)
			)
		end

		def arrogant?()
			party_sym = self.winner.to_sym
			outcome = (
				(self.origin.to_symbol() == party_sym)\
				&&	
				(self.winner.to_sym == party_sym)\
			)
		end

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
			desc = substitute_user(
				desc, user, self.origin, '%ORIGIN%'
			)
			desc = substitute_user(
				desc, user,
				self.tranzaction.symbol_to_party(self.winner), '%WINNER%'
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				self.originator?(user) ? :waiting : :requested
			)
			desc = substitute_user(
				desc, user,
				self.tranzaction.symbol_to_party(self.winner), '%WINNER%'
			)
		end

		def confirmation_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				:requested
			)
puts "substitute_user(#{desc}, #{self.winner}, #{user}, '%WINNER%')"
			desc = substitute_user(
				desc, self.tranzaction.symbol_to_party(self.winner).user,
				self.tranzaction.party_for(user), '%WINNER%'
			)
		end
	end

	#
	# This is created directly by GoalDeclareWinner
	#
	class OutcomeFinalArtifact < ProvisionableArtifact
		PARAMS = {winner: nil}
		IMMUTABLE = true

		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
			desc = substitute_user(
				desc, user,
				self.tranzaction.symbol_to_party(self.winner), '%WINNER%'
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				(self.tranzaction.symbol_to_party(self.winner) == self.tranzaction.party_for(user))\
					? :arrogant : :modest
			)
			desc = substitute_user(
				desc, user,
				self.tranzaction.symbol_to_party(self.winner), '%WINNER%'
			)
		end

	end
	class BetExpiration < Expiration
		DEFAULT_OFFSET = 48 
		DEFAULT_OFFSET_UNITS = :hours
		BASIS_TYPE = :OfferAcceptedArtifact
		ARTIFACT = :BetExpirationArtifact
	end

	class BetExpirationArtifact < ExpiringArtifact
		def status_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_STATUS_MAP,
				:default
			)
		end

		def action_description_for(user)
			desc = lookup_description_template(
				:ARTIFACT_ACTION_MAP,
				:default
			)
		end
	end

end
