#####################################################################################
#
# Make a published offer to the general public, or make an offer to another
# system user.
#
module IBContracts::CL

	class GoalAccept < Goal

		statemachine :machine_state, :init => :s_offered do

			# Offer to an individual
			event :artifact_accept do
				transition :s_offered => :s_accepted
			end
	
			before_transition :s_offered => :s_accepted do |goal|
				transaction = goal.transaction
				accept_goal = transaction.create_goal_accept()
				accept_goal.write_param(:origin_role, transaction.role_of_origin)
				accept_goal.write_param(:responding_role, transaction.other_role)
				true
			end
	
			after_transition :s_private => :s_offer do |goal, transition|
				# message recipient
				#recipient = goal.read_param(:responding_role)
				#goal.transaction.party(recipient).message
				puts "#{self.class}: 
			end
		end

	end

end
