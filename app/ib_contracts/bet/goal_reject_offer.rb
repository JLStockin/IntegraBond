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

		ARTIFACT = nil
		EXPIRE_ARTIFACT = :OfferRejection 
		CHILDREN = []
		FAVORITE_CHILD = false 
		STEPCHILDREN = [:GoalAcceptOffer, :GoalCancelOffer]
		AVAILABLE_TO = [:Party2]
		DESCRIPTION = "Reject offer"

		def execute()
			second_party = self.contract.model_instance(:Party2)
			msg0 = "\n\nOffer rejected by #{second_party.user.first_name} "\
				+ "#{second_party.last_name}."
			Rails.logger.info(msg0)
			msg1 = "Transaction cancelled."
			Rails.logger.info(msg1)

			cancel_transaction()
		end

		def reverse_execution()
			true
		end

		def expire()
			# This goal should never time out.
			false	
		end
	end

	class OfferRejection < Artifact
		PARAMS = {}
	end

end
