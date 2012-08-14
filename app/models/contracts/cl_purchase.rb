###################################################################################
#
# CR Purchase contract and supporting objects 
#
#require "#{Rails.root.join('app', 'model', 'transaction_instance').to_s}"

module IBContracts

	class CLPurchase < Transaction 

		# Needed to make this go
		include TransactionInstance

		# Stuff specific to this contract 
		VERSION = "0.1"
		CONTRACT_NAME = "Craigslist Purchase Contract"
		SUMMARY = "Local, peer-to-peer sales contract.  No dealers, no shipping, cash or certified check only for payment.  Meet in person.  Bond appointment.  If one party is late, a dealer, or requires goods to be shipped, party forfeits bond.  One reschedule permitted (if within allowable time); second reschedule forfeits deposit.  Aggrevied party may waive right to collect deposit for evidence of good faith effort by other party."
		TAGS = "CL Default Purchase"
		AUTHOR_EMAIL = "cschille@gmail.com" 
		ROLES = {buyer: "BUYER", seller: "SELLER"}
		XASSETS = [buyer_deposit: {percentage: 10}, seller_deposit: {percentage: 10}, \
			buyer_fees: {USD: 1}, seller_fees: {USD: 1}, seller_goods: {USD: 100} ]
		INITIAL_MILESTONES = [ {wakeup: {hours: 10}}, {sleep: {hours: 22}} ]
		INITIAL_MACHINE_STATE = :unbound
		INITIAL_FAULT = {buyer: false, seller: false} 

		def originate(role_name)
			raise "Invalid role name '#{role_name}'" if !Transaction.has_role?(role_name)
			@role_of_origin = role_name
			return
		end

		def other_role(role)
			other_role = (role == roles[0]) ? roles[1] : roles[0]
		end

		def intialize()

			super() # Important for state_machine!
		end

		##################################################################################
		#
		# State Machine
		#


# TODO:
# finish events from #7 :s_meeting
# set milestones where appropriate
# create callbacks to deal with expire
# create thread to send expire events
# assign fault and consequences
# figure out how to blow through many states via :expire if we've been languishing in
# one of the :s_requesting_* states.
#
# Use statemachine transaction instance throughout!

		state_machine :state, :initial => :s_bonding do

			#########################################################################
			#
			#                        States and events
			#
			#########################################################################
			#
			# Generic callbacks -- do they work?
			#
			before_transition :any, :to => :any do |transaction, transition|
				Rails.logger.info("** 1 #{transaction} entering as #{transaction.state}")
				true
			end

			after_transition :any, :to => :any do |transaction, transition|
				Rails.logger.info("** 2 #{transaction} exiting as #{transaction.state}" )
				#transaction.state = transaction.state_machine.state	
				#transaction.save
				true
			end

			#
			# Specific callbacks
			#

			# This creates a listing
			before_transition :s_listing, :to => :s_accepting do |transition, transaction|
				@trans = transaction
				self.trans.party(self.trans.role_of_origin()).bond
			end

			# Other party accepts, bonds
			before_transition :s_accepting, :to => :s_confirming do |transaction, transition|
				transaction.party(transaction.other_role()).bond
				Rails.logger.info("** 3 #{transaction} exiting as #{transaction.state}" )
				true
			end

			# Happens on :counter.  Only one party has antied up, so no penalty for
			# countering item, terms, etc.
			before_transition :s_accepting, :to => :s_accepting do |transaction, transition|
				transaction.write_transaction_param(:limit_counter_offer, false)
				true
			end

			# This happens on :counter.  Both parties have antied up, so only reschedule
			# and cancel are allowed.
			before_transition :s_confirming, :to => :s_confirming do |transaction, transition|
				transaction.originate(transaction.other_role())
				transaction.write_transaction_param(:limit_counter_offer, true)
				true
			end

			# This happens on :bond
			before_transition :s_accepting, :to => :s_confirming do |transaction, transition|
				transaction.write_transaction_param(:limit_counter_offer, true)
				transaction.bond(transaction.party(transaction.role_of_origin))
			end

			#
			# The :s_requesting_* states all require that the prior state get cached,
			# and that transaction_params[:requesting_role] is set.
			#
			# The outcome hinges on the other party's decision and can result in the
			# transaction either returning to its prior state, or advancing to another
			# one, typically :s_accepting or :s_cancelled.
			#
			before_transition :s_waiting_no_cancel, :to => :s_requesting_cancel \
					do |transaction, transition|
				transaction.write_transaction_param(:prior_state, :s_waiting_no_cancel)
				true
			end

			before_transition :s_waiting_no_cancel_or_counter, :to => \
				[:s_requesting_cancel, :s_requesting_counter] do |transaction, transition| 
				transaction.write_transaction_param(:prior_state, :s_waiting_no_cancel_or_counter)
				true
			end

			after_transition :s_requesting_cancel, :to => s_cancelled do |transaction, transition| 
				transaction.write_transaction_param(:requesting_role, nil)
				transaction.write_transaction_param(:buyer_fault, false)
				transaction.write_transaction_param(:seller_fault, false)
			end

			# Someone may request a meeting time change in order to get out
			# of a transaction well into it.  Make them at fault, so if they don't carry through,
			# they'll lose their deposit.
			#
			before_transition [:s_requesting_counter, :to => s_confirming] \
					do |transaction, transition| 
				transaction.write_transaction_param(:limit_counter_offer, true)
				requester = transaction.read_transaction_param(:requesting_role)
				transaction.originate(requester)
				fault = (requester.to_s + "_fault").to_sym
				transaction.write_transaction_param(fault, true)
			end

			# Someone (or system) has just confirmed that the other party arrived
			# (:ack_arrived).  Notify other party and proceed to next step.
			before_transition :s_meeting, :to => :s_inspecting do |transaction, transition| 
				meet = transaction.read_transaction_param[:milestones][:meet]
				late = transaction.read_transaction_param[:milestones][:late]
				Transaction.roles.each do |role|
					if !evidence?(	:subject => role.party.user, \
									:object => role.other_party().user, \
									:event => :ack_arrived, \
									:location => transaction.read_transaction_param(:location), \
									:between => [ meet, meet + late ] \
								 ) then
						return false
					end
				end
				true
			end

			# Someone has just claimed that they have arrived (:assert_arrived).
			# Notify other party. 
			after_transition :s_meeting, :to => :s_meeting do
				# TODO: implement
				#evidence = read_transaction_param(:cached_evidence)
				#raise "no evidence cached to be found." \
				#	unless !evidence.nil?
				#raise "evidence is not of expected type.  Did you mean to :assert_arrived" \
				#	+ "instead of :ack_arrived?" \
				#	unless evidence[:subject] == evidence[:object] \
				#	and evidence[:event] == :assert_arrived
				# evidence.message(evidence[:subject].role.user)
				true
			end

			#
			# Buyer can't automatically make a counter offer at this point.  However,
			# she may say there's a problem with the goods and cancel.
			#
			after_transition :s_inspecting, :to => :s_requesting_counter \
					do |transaction, transition|
				transaction.write_transaction_param(:limit_counter_offer, true)
			end

			#
			# Buyer has inspected goods and nobody is at fault here.
			#
			after_transition :s_inspecting, :to => :s_cancelled do |transaction, transition| 
				# Declare draw
				transaction.party(:seller).release_bond()
				transaction.party(:buyer).release_bond()
			end

			#
			# Buyer didn't pay and is at fault 
			#
			after_transition :s_paying, :to => :s_cancelled do |transaction, transition| 
				transaction.party(:buyer).award_bond(party(:seller))
			end

			#
			# The grand finale.  Settle up.  
			#
			before_transition :s_closing, :to => :s_completed do |transaction, transition|
				
				# Declare draw
				transaction.party(:seller).release_bond()
				transaction.party(:buyer).release_bond()
			end

			#########################################################################
			#
			#                        States and events
			#
			#########################################################################

			# :ignomy means this transaction doesn't even get recorded
			state :s_bonding do |transaction, transition| #1
				transition :to => :s_ignomy, :on => :delete_transaction
				transition :to => :s_accepting, :on => :bond, \
					:if => transaction.sufficient_funds?(transaction.role_of_origin)
			end

			state :s_accepting  do |transaction, transition| #2
				transition :to => :s_disputing, :on => :dispute
				transition :to => :same, :on => :counter
				transition :to => :s_bonding, :on => [:expire, :cancel]
				transition :to => :s_confirming_appt, :on => :bond, \
					:if => sufficient_funds?( other_role(role_of_origin()) ) 
			end

			state :s_confirming_appt do #3
				transition :to => :s_disputing, :on => :dispute
				transition :to => :same, :on => :counter
				transition :to => :s_waiting2meet, :on => [:accept, :expire] 
				transition :to => :s_cancelled, :on => :cancel 
			end

			state :s_waiting2meet do #4
				transition :to => :s_disputing, :on => :dispute
				transition :to => :s_confirming_appt, :on => :counter
				transition :to => :s_waiting_no_cancel, :on => :expire
				transition :to => :s_cancelled, :on => :cancel
			end

			# These two states advance to the next via expire 
			state :s_waiting_no_cancel do #5
				transition :to => :s_disputing, :on => :dispute
				transition :to => :s_confirming_appt, :on => :counter
				transition :to => :s_waiting_no_cancel_or_counter, :on => :expire
				transition :to => :s_requesting_cancel, :on => :cancel
			end

			state :s_waiting_no_cancel_or_counter do  #6
				transition :to => :s_disputing, :on => :dispute
				transition :to => :s_meeting, :on => :expire
				transition :to => :s_requesting_counter, :on => :counter
				transition :to => :s_requesting_cancel, :on => :cancel
			end

			state :s_meeting do #7
				transition :to => :s_disputing, :on => :dispute
				transition :to => :s_cancelling, :on => :expire
				transition :to => :s_inspecting, :on => :ack_arrive
				transition :to => :same, :on => :assert_arrive
			end

			state :s_cancel do #8
				transition :to => :s_disputing, :on => :dispute
			end

			state :s_inspecting do #9
				transition :to => :s_disputing, :on => :dispute
				transition :to => :s_paying, :on => :expire
				transition :to => :s_paying, :on => :ack_goods_ok
				transition :to => :s_requesting_counter, :on => :counter
				transition :to => :s_cancelled, :on => :cancel
			end

			state :s_paying do #10
				transition :to => :s_disputing, :on => :dispute
				transition :to => :s_cancelled, :on => :expire # with fault!
				transition :to => :s_requesting_counter, :on => :counter
				transition :to => :s_requesting_cancel, :on => :cancel
			end

			state :s_closing do #11
				transition :to => :s_disputing, :on => :dispute
				transition :to => :s_completed, :on => :expire
				transition :to => :s_requesting_counter, :on => :counter # with fault!
				transition :to => :s_requesting_cancel, :on => :cancel # with fault!
			end

			state :s_completed do #12
				transition :to => :s_disputing, :on => :dispute
			end

			state :s_requesting_cancel do #13
				transition :to => :s_cancelled, :on => :approve
				transition :to => :s_deciding, :on => :deny
				transition :to => :s_pop, :on => :expire
			end

			state :s_requesting_counter do #14
				transition :to => :s_confirming_appt, :on => :approve
				transition :to => :s_deciding, :on => :deny
				transition :to => :s_pop, :on => :expire
			end

			state :s_deciding do #15
				# TODO -- fix
				transition :to => :s_cancelled, :on => :insist # => with !penalty!
				transition :to => :s_pop, :on => [:resume, :expire] #
			end

			state :s_disputing do #16
				# TODO -- fix
				# Operator discretion: 
				# transition :to => # TBD: :s_pop, :s_cancelled, :s_completed
			end

			state :ignomy do

			end

		end # StateMachine

		private

			def have_appointment?
				# TODO: add logic
				return true
			end

			def other_role()
				if role_of_origin == :buyer ? :seller : :buyer
			end

			def sufficient_funds(role)
				# TODO: check if funds are sufficient; if not, record some kind of error
				return true
			end

			def fault?(role)
				raise "'#{role}' is not a valid role" unless Transaction.has_role?(role) 
				read_transaction_param( (role.to_s + "_fault").to_sym )
			end
					
			def bond(role)
				if party(role).reserve_funds() == false then
					# create new evidence 

					# message party

					return false
				else
					return true
				end
			end

	end

end # IBContracts
