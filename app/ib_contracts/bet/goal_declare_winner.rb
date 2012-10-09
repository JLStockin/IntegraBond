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
		EXPIRE_ARTIFACT = :TransactionExpiration 
		CHILDREN = []	# TODO add a GoalDispute, and implement reverse_execution
		FAVORITE_CHILD = true
		STEPCHILDREN = [:GoalMutualCancellation]
		AVAILABLE_TO = [:Party1, :Party2]
		DESCRIPTION = "Indicate the Winner"

		def execute()
			have_a_winner = false
			artifact = self.contract.latest_model_instance(:OutcomeAssertion)

			if (	( (artifact.winner == other_party(artifact.origin)) or \
						(artifact.loser == artifact.origin) \
					) and artifact.counted == false
			) then
				# We have a winner.
				
				# Create a new Artifact noting that and close transaction.	
				result = ::IBContracts::Bet::OutcomeAssertion.new()
				result.contract_id = self.contract_id
				result.mass_assign_params(
					origin: :PartyAdmin, 
					winner: artifact.winner,
					loser: artifact.loser
				)

				# Mark all the artifacts that we used to establish this conclusion.
				artifact.counted = true
				artifact.save!
				result.counted = true
				result.goal = self 
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
				self.contract.disable_active_goals(self)

				user = contract.model_instance(artifact.winner).user
				msg0 = "\n\n#{user.first_name} #{user.last_name} wins."
				Rails.logger.info(msg0)
				msg1 = "Transaction closed."
				Rails.logger.info(msg1)

				have_a_winner = true
			else
				self.machine_state = :s_provisioning
				self.save!
				self.start

				origin = contract.model_instance(artifact.origin).user
				winner = contract.model_instance(artifact.winner).user
				msg = "#{origin.first_name} #{origin.last_name} " \
					+ "asserts that #{winner.first_name} #{winner.last_name} won."
				Rails.logger.info(msg)

				have_a_winner = false 
			end

			have_a_winner	
		end

		# TODO: implement 
		def reverse_execution()
			true
		end

		def expire()
			msg0 = "Transaction expired." 
			Rails.logger.info(msg0)
			cancel_transaction()
			#true
		end

		private
			def other_party(party)
				party == :Party1 ? :Party2 : :Party1
			end
	end

	class OutcomeAssertion < Artifact
		# These should all be Symbols, e.g, ':Party1'
		PARAMS = {\
			origin: :Party1, winner: :Party1, loser: :nil,
			counted: false
		}
	end

	class TransactionExpiration < Artifact
		PARAMS = {}
	end
end

