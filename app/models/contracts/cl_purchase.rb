###################################################################################
#
# CR Purchase contract and supporting objects 
#
require 'state_machine'

module IBContracts

	class CLPurchase < Transaction

		# Constants needed for superclass fcns to work
		VERSION = "0.1"
		CONTRACT_NAME = "Craigslist Purchase Contract"
		SUMMARY = "Local, peer-to-peer sales contract.  No dealers, no shipping, cash or certified check only for payment.  Meet in person.  Bond appointment.  If one party is late, a dealer, or requires goods to be shipped, party forfeits bond.  One reschedule permitted (if within allowable time); second reschedule forfeits deposit.  Aggrevied party may waive right to collect deposit for evidence of good faith effort from other party."
		TAGS = "CL Default Purchase"
		AUTHOR_EMAIL = "cschille@gmail.com" 
		ROLES = {buyer: "BUYER", seller: "SELLER"}
		XASSETS = [buyer_deposit: {percentage: 10}, seller_deposit: {percentage: 10}, \
			seller_goods: {USD: 100} ]
		INITIAL_MILESTONES = [ {wakeup: {hours: 10}}, {sleep: {hours: 22}} ]
		INITIAL_MACHINE_STATE = :unbound
		INITIAL_FAULT = {buyer: false, seller: false} 

		attr_accessor :name, :state_cache, :state

		def intialize()

			super() # Important for state_machine!
		end

		state_machine :state, :initial => :s_state1 do

			# Normal states
			before_transition any => any do |transaction, transition|
				puts "** #{transaction} entering as #{transaction.state}" 
			end
			after_transition any => any do |transaction, transition|
				puts "** #{transaction} exiting as #{transaction.state}" 
			end

			# Unusual states
			before_transition all - [:s_unusual] => :s_unusual do |transaction, transition|
				puts "**** #{transaction} setting cache to #{transaction.state}" 
				transaction.state_cache	= transaction.state
			end
			after_transition :s_unusual => :s_unusual do |transaction, transition|
				transaction.state = transaction.state_cache
				puts "**** #{transaction} restoring from cache to #{transaction.state}" 
			end

			event :_next do
				transition :s_state1 => :s_state2
				transition :s_state2 => :s_state3
				transition :s_state3 => :s_state1
				transition :s_unusual => same 
			end

			event :_unusual do
				transition all => :s_unusual
			end

		end # StateMachine

	end

end # IBContracts
