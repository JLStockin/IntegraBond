#####################################################################################
#
#
require 'state_machine'

module IBContracts::Bet

	class GoalMutualCancellation < Goal

		#########################################################################
		#
		# The first party has tendered an offer to the second.  The second may
		# Accept or Reject.
		#
		#########################################################################

		ARTIFACT = :MutualCancellation
		CHILDREN = []
		STEPCHILDREN = [:GoalDeclareWinner]

		def execute()
			
			requests = self.contract.model_instances(:MutualCancellation)
			party1_confirms = false
			party2_confirms = false

			requests.each do |request|
				party1_confirms = true if request.origin == :Party1 
				party2_confirms = true if request.origin == :Party2 
			end

			if party1_confirms and party2_confirms then

				# We have the consent of both.  Create an Artifact to that effect
				# and disable transaction. 
				cancellation = self.namespaced_constant(:MutualCancellation).new()
				cancellation.contract_id = self.contract_id
				cancellation.origin = :PartyAdmin
				cancellation.save!

				self.contract.reverse_completed_goals(self)
				self.contract.disable_active_goals(self)
			end
		end

		def reverse_execution()
		end

		def expire()
		end
	end

	class MutualCancellation < Artifact
		# Origin should be a Symbol, like ':Party1'
		PARAMS = {\
			origin: nil, 
		}
	end

end

