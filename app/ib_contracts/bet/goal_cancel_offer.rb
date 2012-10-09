#####################################################################################
#
#
require 'state_machine'

module IBContracts::Bet

	class GoalCancelOffer < Goal

		#########################################################################
		#
		# This can happen during one critical period of time: Party1 is trying to create
		# an offer, and gives up (presses the cancel button).
		#
		# This is the only case where we will purge a transaction from the database.
		#
		# In this state, only the transaction (Contract) and Goal have been created.
		# No money is yet involved.
		#
		# We need to do the same thing if GoalTenderOffer expires.
		#
		#########################################################################

		ARTIFACT = nil 
		EXPIRE_ARTIFACT = :OfferWithdrawl
		CHILDREN = []
		FAVORITE_CHILD = false 
		STEPCHILDREN = [:GoalAcceptOffer, :GoalRejectOffer]
		AVAILABLE_TO = [:Party1]
		DESCRIPTION = "Cancel offer"

		def execute()
			first_party = self.contract.model_instance(:Party1)
			msg0 = "\n\nOffer retracted by #{first_party.user.first_name} "\
				+ "#{first_party.user.last_name}."
			Rails.logger.info(msg0)
			msg1 = "Transaction cancelled."
			Rails.logger.info(msg1)

			cancel_transaction()

			true
		end

		def reverse_execution()
			true
		end

		def expire()
			# This Goal should never time out.
			false	
		end
		
	end

	class OfferWithdrawl < Artifact
		PARAMS = {}
	end


end

