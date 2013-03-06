#
# View code specific to this contract type.  Unfortunately, Helpers don't support namespaces,
# so it has to live down with the contract model
#
class Contracts::Bet::ModelDescriptor < ModelDescriptor

	# This is also defined in app/helpers/application_helper.rb
	SITE_NAME = "IntegraBond"

	#
	# Transaction status
	#
	def self.status_for(tranzaction, user)
		party = ActiveRecord::Base.const_to_symbol(tranzaction.party_for(user).class)
		klass_or_artifact = tranzaction.status_object()
		status = "Error"
		if klass_or_artifact.is_a?(Artifact) then
			status = STATUS_ARTIFACT_OBJECT_MAP[\
				ActiveRecord::Base.const_to_symbol(klass_or_artifact.class)\
			]
		elsif klass_or_artifact.is_a?(Symbol) then
			status = STATUS_ARTIFACT_SYMBOL_MAP[party][klass_or_artifact]
		end
		status ||= "Error: #{klass_or_artifact.to_s} couldn't be mapped"
	end

	# Lookup table: summarize most likely step for given Tranzaction and User
	#
	# We don't have active Goals.  Artifact is the last Goal's artifact, and it tells us
	# what happened.
	#
	STATUS_ARTIFACT_OBJECT_MAP = {
		:OfferPresentedArtifact			=> "Offer presented",
		:OfferAcceptedArtifact			=> "Offer accepted",
		:OfferExpirationArtifact		=> "Offer expired",
		:OfferWithdrawnArtifact			=> "Offer withdrawn",
		:OutcomeAssertionArtifact		=> "Completed",
		:MutualCancellationArtifact		=> "Mutual cancel",
		:OfferRejectedArtifact			=> "Offer rejected",
		:TermsArtifact					=> "Incomplete",
		:BetExpirationArtifact			=> "Expired (no results)"
	}

	# Lookup table: summarize most likely step for given Tranzaction and User
	#
	# We've got active goals.  Presumably, we want to succeed, so the Contract's
	# current_success_goal()'s artifact tells us what should happen next
	#
	STATUS_ARTIFACT_SYMBOL_MAP = {
		Party1: {
			:OfferPresentedArtifact			=> "Incomplete",
			:OfferAcceptedArtifact			=> "Waiting",
			:OfferExpirationArtifact		=> "Error",	# error: this isn't on the success path
			:OfferWithdrawlArtifact			=> "Error",	# error: this isn't on the success path
			:OutcomeAssertionArtifact		=> "Attention Required",
			:MutualCancellationArtifact		=> "Error",	# error: this isn't on the success path
			:OfferRejectedArtifact			=> "Error",	# error: this isn't on the success path
			:BetExpirationArtifact			=> "Error"	# error: this isn't on the success path
		},
		Party2: {
			:OfferPresentedArtifact			=> "Error",	# 2nd Party shouldn't have entered yet
			:OfferAcceptedArtifact			=> "Attention Required",
			:OfferExpirationArtifact		=> "Error",	# error: this isn't on the success path
			:OfferWithdrawlArtifact			=> "Error",	# error: this isn't on the success path
			:OutcomeAssertionArtifact		=> "Attention Required",
			:MutualCancellationArtifact		=> "Error",	# error: this isn't on the success path
			:OfferRejectedArtifact			=> "Error",	# error: this isn't on the success path
			:BetExpirationArtifact			=> "Error"	# error: this isn't on the success path
		},
	}

	ARTIFACT_DESCRIPTIONS = {
		:TermsArtifact				=> "Offer saved",
		:OfferWithdrawnArtifact		=> "Offer withdrawn",
		:OfferAcceptedArtifact		=> "Offer accepted!",
		:OfferRejectedArtifact		=> "Offer rejected",
		:OfferExpiredArtifact		=> "Offer expired",
		:BetExpiredArtifact			=> "Bet expired",
		:MutualCancellationArtifact	=> "Cancellation requested",
		:OutcomeAssertionArtifact	=> "Winner claimed",
		:OtherPartyNotFoundArtifact => "Other party couldn't be identified"
	}

	VALUABLE_DESCRIPTIONS = {
		:Party1Fees		=> "Transaction fees (to be paid by loser)",
		:Party2Fees		=> "Transaction fees (to be paid by loser)",
		:Party1Bet		=> "Bet Amount",
		:Party2Bet		=> "Bet Amount",
	}

	GOAL_DESCRIPTIONS = {
		:GoalTenderOffer			=> "Create",
		:GoalCancelOffer			=> "Retract",
		:GoalAcceptOffer			=> "Accept",
		:GoalRejectOffer			=> "Decline",
		:GoalMutualCancellation		=> "Cancel (by mutual agreement)",
		:GoalDeclareWinner			=> "Declare Winner"
	}

	BASIS_TYPE_DESCRIPTIONS = {
		:OfferPresentedArtifact		=> "after receipt of offer",
		:OfferAcceptedArtifact		=> "after acceptance of offer"
	}

	EXPIRATION_LABELS = {
		:OfferExpiration			=> "Other party must accept by: ",
		:BetExpiration				=> "Outcome to be confirmed no later than: "
	}

	def self.goal(goal)
		GOAL_DESCRIPTIONS[goal.class.to_sym]
	end

	def self.artifact(artifact)
		ARTIFACT_DESCRIPTIONS[artifact.class.to_sym]
	end

	def self.contract_objective()
		"Make a Bet"
	end

	PARTY_DESCRIPTIONS = {
		:Party1	=> 'First Party',
		:Party2	=> 'Second Party',
		:PParty1 => 'First Test Party',
		:PParty2 => 'Second Test Party'
	}

	PARTY_LOCATION_NOTICES = {
		:not_found 		=> "%SITE_NAME% user for '%PARTY%' could not be found.  Invite to %SITE_NAME%?",
		:invite			=> "%PARTY% will be invited to %SITE_NAME%",
		:resolved		=> "Party %PARTY% resolved",
		:identified		=> "Party identified: %PARTY%",
		:published		=> "Offer will be published (made available to any user)"
	}

	CONTACT_OTHER_PARTY = 'Contact other party as: '

	def self.party_class_description(party_klass)
		PARTY_DESCRIPTIONS[ActiveRecord::Base.const_to_symbol(party_klass)]
	end
		
	def self.party_role(party)
		PARTY_DESCRIPTIONS[party.class.to_sym]
	end

	CONTRACT_NAME =	"Two-Party Wager"

	SUMMARY = "Bet between two parties."

end
