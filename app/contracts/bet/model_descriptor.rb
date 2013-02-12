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
	def self.status_for(tranzaction)
		klass_or_artifact = tranzaction.status_object()
		if klass_or_artifact.is_a?(Artifact) then
			status = STATUS_ARTIFACT_OBJECT_MAP[\
				ActiveRecord::Base.const_to_symbol(klass_or_artifact.class)\
			]
		else
			status = STATUS_ARTIFACT_SYMBOL_MAP[klass_or_artifact] 
		end
		status	
	end

	# Lookup table:
	#
	# We don't have active Goals.  Artifact is the last Goal's artifact, and it tells us
	# what happened.
	#
	STATUS_ARTIFACT_OBJECT_MAP = {
		:OfferPresentedArtifact			=> "Error",
		:OtherPartyNotFoundArtifact		=> "Other party couldn't be located",
		:OfferAcceptedArtifact			=> "Error",
		:OfferExpirationArtifact		=> "Offer expired",
		:OfferWithdrawnArtifact			=> "Offer withdrawn",
		:OutcomeAssertionArtifact		=> "Completed",
		:MutualCancellationArtifact		=> "Mutual cancel",
		:OfferRejectedArtifact			=> "Offer rejected",
		:BetExpirationArtifact			=> "Expired (no results)"
	}

	# Lookup table:
	#
	# We've got active goals.  Presumably, we want to succeed, so the Contract's
	# current_success_goal()'s artifact tells us what should happen next
	#
	STATUS_ARTIFACT_SYMBOL_MAP = {
		:OfferPresentedArtifact			=> "Offer tendered",
		:OtherPartyNotFoundArtifact		=> "Error",
		:OfferAcceptedArtifact			=> "Offer accepted",
		:OfferExpirationArtifact		=> "Error",
		:OfferWithdrawlArtifact			=> "Error",
		:OutcomeAssertionArtifact		=> "Pending results",
		:MutualCancellationArtifact		=> "Error",
		:OfferRejectedArtifact			=> "Error",
		:BetExpirationArtifact			=> "Error"
	}

	ARTIFACT_DESCRIPTIONS = {
		:OfferCompositionExpiration => "Offer creation timed out",
		:BadContactArtifact			=> "Other party not found.  Invite to #{SITE_NAME}?",
		:OtherPartyNotFoundArtifact => "Other party couldn't be identified"
	}

	VALUABLE_DESCRIPTIONS = {
		:Party1Fees		=> "Transaction fees (to be paid by loser)",
		:Party2Fees		=> "Transaction fees (to be paid by loser)",
		:Party1Bet		=> "Bet Amount",
		:Party2Bet		=> "Bet Amount",
	}

	GOAL_DESCRIPTIONS = {
		:GoalTenderOffer			=> "Create an offer",
		:GoalCancelOffer			=> "Retract offer",
		:GoalAcceptOffer			=> "Accept offer",
		:GoalRejectOffer			=> "Decline offer",
		:GoalMutualCancellation		=> "Cancel bet (if mutual agreement)",
		:GoalDeclareWinner			=> "Affirm bet outcome"
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

	CONTACT_OTHER_PARTY = 'Contact other party as: '

	def self.party_class_description(party_klass)
		PARTY_DESCRIPTIONS[ActiveRecord::Base.const_to_symbol(party_klass)]
	end
		
	def self.party_role(party)
		PARTY_DESCRIPTIONS[party.class.to_sym]
	end

	def self.contract_name
		"Two-Party Wager"
	end

	def self.contract_summary
		"Bet between two parties."
	end

	def self.author_email
		"cschille@IntegraBond.com" 
	end

end
