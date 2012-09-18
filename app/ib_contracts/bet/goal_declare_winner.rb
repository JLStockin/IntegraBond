#####################################################################################
#
#
require 'state_machine'

module IBContracts::Bet

	class GoalDeclareWinner < Goal

		#########################################################################
		#
		# The first party has tendered an offer to the second.  The second may
		# Accept or Reject.
		#
		#########################################################################

		ARTIFACT = :OutcomeAssertion
		CHILDREN = []	# TODO add a GoalDispute, and implement reverse_execution
		STEPCHILDREN = [:GoalMutualCancellation]

		def execute()
			winner = false
			artifacts = self.contract.model_instances(:OutcomeAssertion)
			artifacts.each do |artifact|
				if (	(artifact.winner == other_party(artifact.origin)) or \
						(artifact.loser == artifact.origin) \
				) then
					# We have a winner.  Create a new Artifact noting that and close transaction.	
					result = ::IBContracts::Bet::OutcomeAssertion.new()
					result.contract_id = self.contract_id
					result.mass_assign_params(
						origin: :PartyAdmin, 
						winner: artifact.winner,
						loser: artifact.loser \
					)
					result.save!

					# Dispense bet monies
					to_release = (result.winner == :Party1)\
						? self.contract.party1_bet \
						: self.contract.party2_bet 
					to_transfer = (result.winner == :Party1)\
						? self.contract.party2_bet : self.contract.party1_bet 

					to_transfer.disposition = to_release.origin 
					to_release.release
					to_transfer.transfer

					# Dispense fees.  Winner pays the house.
					to_release = (result.winner == :Party1)\
						? self.contract.party2_fees\
						: self.contract.party1_fees
					to_transfer = (result.winner == :Party1)\
						? self.contract.party1_fees\
						: self.contract.party2_fees 
					to_transfer.disposition = self.contract.house() 
					to_release.release
					to_transfer.transfer

					# We're done.  Disable all goals.
					self.contract.disable_active_goals()
					winner = true
				end
			end
			if winner == false then
				self.machine_state = :s_provisioning
				self.save!
				self.start
			end
		end

		# TODO: implement 
		def reverse_execution()
		end

		def expire()
			self.contract.reverse_completed_goals()
			self.contract.disable_active_goals()
		end

		private
			def other_party(party)
				party == :Party1 ? :Party2 : :Party1
			end
	end

	class OutcomeAssertion < Artifact
		# These should all be Symbols, e.g, ':Party1'
		PARAMS = {\
			origin: :Party1, winner: :Party1, loser: :Party2,
		}
	end

end

