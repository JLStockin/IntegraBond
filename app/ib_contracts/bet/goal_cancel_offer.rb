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

		ARTIFACT = :OfferCancel
		CHILDREN = []
		STEPCHILDREN = [:GoalTenderOffer]

		def execute()
			self.contract.destroy()
		end

		def reverse_execution()
		end

		def expire()
		end

	end

	class OfferCancel < Artifact
		PARAMS = {\
			origin: :Party1
		}
	end
end

