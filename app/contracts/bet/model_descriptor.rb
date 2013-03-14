#
# View code specific to this contract type.  Unfortunately, Helpers don't support namespaces,
# so it has to live down with the contract model
#
class Contracts::Bet::ModelDescriptor < ModelDescriptor

	# This is also defined in app/helpers/application_helper.rb
	SITE_NAME = "IntegraBond"

	#
	# Artifact is the last Goal's artifact, and it tells us what happened.
	#
	ARTIFACT_STATUS_MAP = {
		:TermsArtifact					=> { default: "Editing (incomplete)"},
		:OfferPresentedArtifact			=> { default: "%ORIGIN% presented offer"},
		:OfferAcceptedArtifact			=> { default: "%ORIGIN% accepted offer"},
		:OfferWithdrawnArtifact			=> { default: "%ORIGIN% withdrew offer"},
		:OutcomeAssertionArtifact		=> { default: "%ORIGIN% asserted that %WINNER% won"},
		:OutcomeFinalArtifact			=> { default: "%WINNER% won"},
		:MutualCancellationRequestArtifact	=> { default: "%ORIGIN% requested cancel"},
		:MutualCancellationArtifact		=> { default: "Cancelled"},
		:OfferRejectedArtifact			=> { default: "%ORIGIN% rejected offer"},
		:OfferExpirationArtifact		=> { default: "Offer expired"},
		:BetExpirationArtifact			=> { default: "Expired (no results)"}
	}

	IDENTITY_MAPPINGS = {
		:you								=> 'you',
		:other								=> '%FIRSTNAME% %LASTNAME%' 
	}

	#
	# This table tells us whose turn it is.  %STATUS% should be replaced with the appropriate status:
	# 'Waiting', 'Attention required', 'Pick a winner', etc.
	#
	ARTIFACT_ACTION_MAP = {
		:TermsArtifact => {
			waiting: 	"Waiting",
			required: 	"Editing (incomplete)"
		},
		:OfferPresentedArtifact => {
			waiting: 	"Waiting",
			required: 	"Input required"
		},
		:OfferAcceptedArtifact => {
			waiting: 	"Ready to indicate winner?",
			requested: 	"Ready to indicate winner?"
		},
		:OfferExpirationArtifact => {
			default: 	"Expired"
		},
		:OfferWithdrawnArtifact => {
			default: 	"Cancelled"
		},
		:OutcomeAssertionArtifact => {
			waiting: 	"Seeking confirmation %WINNER% won",
			requested: 	"Please confirm %WINNER% won"
		},
		:OutcomeFinalArtifact => {
			modest: 	"%WINNER% won",
			arrogant:	"%WINNER% won"
		},
		:MutualCancellationRequestArtifact => {
			default: 	"Cancel? (%ORIGIN%)"
		},
		:MutualCancellationArtifact => {
			default:	"Cancelled (mutual)"
		},
		:OfferRejectedArtifact => {
			default: 	"Declined by %ORIGIN%"
		},
		:BetExpirationArtifact => {
			default: 	"Expired"
		}
	}

	ID_MAPPINGS = {
		:you				=> 	'you',
		:other				=>  '%FIRSTNAME% %LASTNAME%'
	}

	VALUABLE_DESCRIPTIONS = {
		:Party1Fees		=> "Transaction fees (to be paid by loser)",
		:Party2Fees		=> "Transaction fees (to be paid by loser)",
		:Party1Bet		=> "Bet Amount",
		:Party2Bet		=> "Bet Amount",
	}

	GOAL_DESCRIPTIONS = {
		:GoalTenderOffer			=> "Create",
		:GoalWithdrawOffer			=> "Withdraw",
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

	# TODO move these next two to ActiveRecord::Base
	def self.goal(goal)
		ret = GOAL_DESCRIPTIONS[goal.to_symbol]
		raise "missing description entry for goal: #{goal.to_symbol}" unless ret
		ret
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
