module TransactionsHelper

	def status_for(transaction)
		klass_or_artifact = transaction.status_object()
		if klass_or_artifact.is_a?(Artifact) then
			status = STATUS_ARTIFACT_OBJECT_MAP[Object.const_to_symbol(klass_or_artifact.class)] 
		else
			status = STATUS_ARTIFACT_SYMBOL_MAP[klass_or_artifact] 
		end
		status	
	end

	# We don't have active Goals.  Artifact is the last Goal's artifact, and it tells us
	# what happened.
	#
	STATUS_ARTIFACT_OBJECT_MAP = {
		:OfferArtifact			=> "Error",
		:OfferAcceptance		=> "Error",
		:OfferExpiration		=> "Offer expired",
		:OfferWithdrawl			=> "Offer withdrawn",
		:OutcomeAssertion		=> "Completed",
		:TransactionExpiration	=> "Transaction expired",
		:MutualCancellation		=> "Mutual cancel",
		:OfferRejection			=> "Offer rejected"
	}

	# We've got active goals.  Presumably, we want to succeed, so the Contract's
	# current_success_goal()'s artifact tells us what should happen next
	#
	STATUS_ARTIFACT_SYMBOL_MAP = {
		:OfferArtifact			=> "Offer tendered",
		:OfferAcceptance		=> "Offer accepted",
		:OutcomeAssertion		=> "Pending results",
		:OfferExpiration		=> "Error",
		:OfferWithdrawl			=> "Error",
		:TransactionExpiration	=> "Error",
		:MutualCancellation		=> "Error",
		:OfferRejection			=> "Error"
	}

end
