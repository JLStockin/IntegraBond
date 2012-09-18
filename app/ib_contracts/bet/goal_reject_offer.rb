#####################################################################################
#
#
require 'state_machine'

module IBContracts::Bet

	class GoalRejectOffer < Goal

		#########################################################################
		#
		# The first party is authoring a contract.  Goal is to tender this offer
		# to the second party.
		#
		#########################################################################

		ARTIFACT = :OfferRejection
		CHILDREN = []
		STEPCHILDREN = [:GoalAcceptOffer]

		def execute(artifact)
			self.contract.reverse_completed_goals()
			self.contract.disable_active_goals()
			true
		end

		def reverse_execution()
		end

		def expire()
		end
	end

	class OfferRejection < Artifact
		PARAMS = {\
			origin: :Party2
		}
	end

end
