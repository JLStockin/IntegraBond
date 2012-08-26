#####################################################################################
#
# Make a published offer to the general public, or make an offer to another
# system user.
#
module IBContracts::CL

	class GoalOffer < Goal

		statemachine :machine_state, :init => :s_private do

			# Controller has received a transaction creation page and created a listing
			# Artifact and this Goal.  Create the 'accept' goal and notify the other
			# Party.
			#
			before_transition :s_private => :s_offered do |goal, transition|
				artifact = transition.args[0]
				transaction = goal.transaction
				accept_goal = transaction.build_goal_accept()
				seller = transaction.read_param(:seller)
				buyer = transaction.read_param(:seller)
				accept_goal.write_param(:origin_role, transaction.get_subject_party)
				accept_goal.write_param(:responding_role, :anyone)
				true
			end
	
			before_transition :s_private => :s_published do |goal, transition|
				artifact = transition.args[0]
				transaction = goal.transaction
				accept_goal = transaction.build_goal_accept()
				true
			end

			after_transition :s_private => :s_offer do |goal, transition|
				artifact = transition.args[0]
				# message recipient
				recipient = goal.read_param(:responding_role)
				goal.transaction.party(recipient).message
			end

			# Offer to an individual.
			event :artifact_offer do |artifact|
				transition :s_private => :s_offered
			end
	
			# Offer published by :seller or :buyer
			event :artifact_published_offer do |artifact|
				transition :s_private => :s_published
			end
	
		end

	end

end

Parties: buyer_email, seller_email, originator
Valuables: buyer_deposit, seller_deposit, fees, item (name, description, URL)
Goal data:
