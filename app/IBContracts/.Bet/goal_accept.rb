#####################################################################################
#
#
module IBContracts::Bet

	class GoalAccept < Goal

		#########################################################################
		#
		#                       StateMachine 
		#
		#########################################################################

		#
		# TODO complete these! ----------------------------------------
		#
		PARAMS = {a: :no, b: :no }

		statemachine :machine_state, :init => :s_initial do

			inject_start()
			inject_provisioning()

			# challenge
			event :offer do
				transition :s_initial => :s_issued_offer
			end
			before_transition :s_initial => :s_issued_offer do |goal, transition|
				p1 = goal.transaction.qualified_const(:Party1).new(\
					transaction_id: goal.transaction.id,
					user: User.find_by_email("cschille@example.com")\
				)
				goal.transaction.parties << p1

				p1_bet = goal.transaction.qualified_const(:Party1Bet).new(\
					transaction_id: goal.transaction.id,
					value: goal.transaction.class.bond_for( :Party1 ),
					origin: p1,
					disposition: p1 \
				)
				p1_bet.reserve
				goal.transaction.valuables << p1_bet

				p1_fees = goal.transaction.qualified_const(:Party1Fees).new(\
					transaction_id: goal.transaction.id,
					value: goal.transaction.fees(),
					origin: p1,
					disposition: p1 \
				)
				p1_fees.reserve
				goal.transaction.valuables << p1_fees
			end

			# accept
			event :artifact_accept do
				transition :s_issued_offer => :s_accepted
			end
			before_transition :s_issued_offer => :s_accepted do |goal, transition|
				p2 = goal.transaction.qualified_const(:Party2).new(\
					transaction_id: goal.transaction.id,
					user: User.find_by_email("sinolean@example.com")\
				)
				goal.transaction.parties << p2

				p2_bet = goal.transaction.qualified_const(:Party2Bet).new(\
					transaction_id: goal.transaction.id,
					value: goal.transaction.class.bond_for(:Party2),
					origin: p2,
					disposition: p2 \
				)
				p2_bet.reserve
				goal.transaction.valuables << p2_bet

				p2_fees = goal.transaction.qualified_const(:Party2Fees).new(\
					transaction_id: goal.transaction.id,
					value: goal.transaction.fees() / 2,
					origin: p2,
					disposition: goal.transaction.party(house()) \
				) 
				p2_fees.reserve
				goal.transaction.valuables << p2_fees

				goal.transaction.valuable(:Party1Fees).disposition \
					= goal.transaction.party(house())
				goal.transaction.valuable(:Party2Fees).disposition \ 
					= goal.transaction.party(house())
			end

			# decline
			event :artifact_decline do
				transition :s_issued_offer => :s_expired
			end
			before_transition :s_issued_offer => :s_expired do |goal, transition|
				goal.cancel_deal
			end

			# outcome
			event :artifact_outcome do
				transition :s_accepted => :s_closed
			end
			before_transition :s_accepted => :s_closed do |goal, transition|
				raise "outcome not specified" if transition.args[0].nil?

				party1_prevails = transition.args[0]
				party2_prevails = !party1_prevails 

				goal.transaction.valuable(:Party1Fees).disposition \ 
					= goal.transaction.party(house())
				goal.transaction.valuable(:Party2Fees).disposition \ 
					= goal.transaction.party(house())
				goal.transaction.valuable(:Party1Fees).transfer
				goal.transaction.valuable(:Party2Fees).transfer

				if party1_prevails then
					goal.transaction.valuable(:Party1Bet).release
					goal.transaction.valuable(:Party2Bet).disposition \
						= goal.transaction.party(:Party1)
					goal.transaction.valuable(:Party2Bet).transfer
				else
					goal.transaction.valuable(:Party2Bet).release
					goal.transaction.valuable(:Party1Bet).disposition \
						= goal.transaction.party(:Party2)
					goal.transaction.valuable(:Party1Bet).transfer
				end
			end

			inject_expiration()

			before_transition all => :s_expired do |goal, transition|
				goal.cancel_deal
			end

		end

		def cancel_deal
			party1 = self.transaction.party(:Party1)
			party2 = self.transaction.party(:Party2)

			self.transaction.valuable(:Party1Fees).disposition = party1 
			self.transaction.valuable(:Party1Fees).release
			self.transaction.valuable(:Party2Fees).disposition =  party2
			self.transaction.valuable(:Party2Fees).release

			self.transaction.valuable(:Party1Bet).disposition = party1 
			self.transaction.valuable(:Party1Bet).release
			self.transaction.valuable(:Party2Bet).disposition =  party2
			self.transaction.valuable(:Party2Bet).release
		end
	end
end
