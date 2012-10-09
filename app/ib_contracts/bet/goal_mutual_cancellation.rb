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
		EXPIRE_ARTIFACT = nil 
		CHILDREN = []
		FAVORITE_CHILD = false 
		STEPCHILDREN = [:GoalDeclareWinner]
		AVAILABLE_TO = [:Party1, :Party2]
		DESCRIPTION = "Cancel (with other party's approval)"

		def execute()
			
			have_cancellation = false

			requests = self.contract.model_instances(:MutualCancellation)
			confirmations = {}
			confirmations[:Party1] = [nil, false]
			confirmations[:Party2] = [nil, false]

			requests.each do |request|
				confirmations[:Party1] = [request, true] \
					if request.origin == :Party1 and request.counted == false
				confirmations[:Party2] = [request, true] \
					if request.origin == :Party2 and request.counted == false
			end

			requester = contract.latest_model_instance(:MutualCancellation).origin
			requester = contract.model_instance(requester).user
			msg = "\n\n#{requester.first_name} #{requester.last_name} has requested cancellation."
			Rails.logger.info(msg)

			if confirmations[:Party1][1] and confirmations[:Party2][1] then 

				# We have the consent of both.  Create an Artifact to that effect
				# and disable transaction. 
				# Also, mark all three artifacts as counted
				cancellation = self.contract.namespaced_class(:MutualCancellation).new()
				cancellation.contract_id = self.contract_id
				cancellation.goal_id = self.id
				cancellation.origin = :PartyAdmin
				cancellation.counted = true
				cancellation.save!

				confirmations[:Party1][0].counted = true
				confirmations[:Party1][0].save!
				confirmations[:Party2][0].counted = true
				confirmations[:Party2][0].save!

				cancel_transaction()

				msg2 = "Transaction cancelled by mutual agreement."
				Rails.logger.info(msg2)

				have_cancellation = true
			else
				self.machine_state = :s_provisioning
				self.save!
				self.start
				have_cancellation = false 
			end

			have_cancellation	
		end

		def reverse_execution()
			true
		end

		def expire()
			# This goal should never time out 
			false	
		end
	end

	class MutualCancellation < Artifact
		# Origin should be a Symbol, like ':Party1'
		PARAMS = {\
			origin: :Party1,
			counted: false
		}
	end

end

