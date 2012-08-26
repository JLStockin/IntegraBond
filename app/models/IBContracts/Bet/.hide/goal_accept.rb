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

		statemachine :machine_state, :init => :s_initial do

			# challenge
			event :offer do
				transition :s_initial => :s_issued_offer
			end
			before_transition :s_initial => :s_issued_offer do |goal, transition|
				p1 = goal.transaction.qualified_const( :PartyParty1 ).new(\
					transaction_id: goal.transaction.id,
					user: User.find_by_email("cschille@example.com")\
				)
				p1_bet = goal.transaction.qualified_const(ValuableParty1Bet).new(\
					transaction_id: goal.transaction.id,
					value: goal.transaction.class.bond(PartyParty1),
					origin: p1,
					disposition: p1 \
				)
				p1_bet.reserve
				p1_fees = goal.transaction.qualified_const(:ValuableParty1Fees).new(\
					transaction_id: goal.transaction.id,
					value: goal.transaction.fees(),
					origin: p1,
					disposition: p1 \
				)
				p1_fees.reserve
			end

			# accept
			event :artifact_accept do
				transition :s_issued_offer => :s_accepted
			end
			before_transition :s_issued_offer => :s_accepted do |goal, transition|
				p2 = goal.transaction.qualified_const(:PartyParty2).new(\
					transaction_id: goal.transaction.id,
					user: User.find_by_email("sinolean@example.com")\
				)
				p2_bet = goal.transaction.qualified_const(ValuableParty2Bet).new(\
					transaction_id: goal.transaction.id,
					value: goal.transaction.class.bond(PartyParty2),
					origin: p2,
					disposition: p2 \
				)
				p2_bet.reserve
				p2_fees = goal.transaction.qualified_const(:ValuableParty2Fees).new(\
					transaction_id: goal.transaction.id,
					value: goal.transaction.fees() / 2,
					origin: p2,
					disposition: goal.transaction.party(AdminParty) \
				) 
				p2_fees.reserve
				goal.transaction.valuable(ValuableParty1Fees).disposition \
					= goal.transaction.party(AdminParty)
				goal.transaction.valuable(ValuableParty2Fees).disposition \ 
					= goal.transaction.party(AdminParty)
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
				goal.transaction.valuable(ValuableParty1Fees).disposition \ 
					= goal.transaction.party(AdminParty)
				goal.transaction.valuable(ValuableParty2Fees).disposition \ 
					= goal.transaction.party(AdminParty)
				goal.transaction.valuable(ValuableParty1Fees).transfer
				goal.transaction.valuable(ValuableParty2Fees).transfer
				if transition.args[0] then
					# Party1 prevailed
					goal.transaction.valuable(ValuableParty1Bet).release
					goal.transaction.valuable(ValuableParty2Bet).disposition \
						= goal.transaction.party(PartyParty1)
					goal.transaction.valuable(ValuableParty2Bet).transfer
				else
					# Party2 prevailed
					goal.transaction.valuable(ValuableParty2Bet).release
					goal.transaction.valuable(ValuableParty1Bet).disposition \
						= goal.transaction.party(PartyParty2)
					goal.transaction.valuable(ValuableParty1Bet).transfer
				end
			end

			# expiration -- call this to get goals to de-active themselves
			event :time_check do
				transition all => :s_expired, \
					:if => lambda {|goal| DateTime.now < goal.expires_at
			end
			before_transition all => :s_expired do |goal, transition|
				goal.cancel_deal
			end

		end

		def cancel_deal
			party1 = self.transaction.party(PartyParty1)
			party2 = self.transaction.party(PartyParty2)

			self.transaction.valuable(ValuableParty1Fees).disposition = party1 
			self.transaction.valuable(ValuableParty1Fees).release
			self.transaction.valuable(ValuableParty2Fees).disposition =  party2
			self.transaction.valuable(ValuableParty2Fees).release

			self.transaction.valuable(ValuableParty1Bet).disposition = party1 
			self.transaction.valuable(ValuableParty1Bet).release
			self.transaction.valuable(ValuableParty2Bet).disposition =  party2
			self.transaction.valuable(ValuableParty2Bet).release
		end
	end
end
