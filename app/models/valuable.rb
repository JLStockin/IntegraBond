require 'state_machine'

class Valuable < ActiveRecord::Base

	raise "you must derive a class from Valuable" if self.class == Valuable

	#
	# ActiveRecord setup
	#
	include ActiveModel::Validations

	# Monetization
	monetize	:value_cents

	# Accessibility
	attr_accessor :user_id, :transaction_id
	#attr_reader :type ???

	# Associations
	belongs_to	:transaction

	##################################################################################
	#
	# Statemachine
	#
	state_machine :machine_state, :initial => :s_initial do

		# :reserve
		event :reserve do
			transition :s_initial => :s_reserved
		end
		before_transition :s_initial => :s_reserved do |valuable, transition|
			xaction = Xaction.new(op: :reserve)
			xaction.amount = valuable.value
			xaction.hold = 0 
			xaction.primary = valuable.origin.user.account
			xaction.save!
		end

		# :release
		event :release do
			transition :s_reserved => :s_initial
		end
		before_transition :s_reserved => :s_initial do |valuable, transition|
			xaction = Xaction.new(op: :release)
			xaction.amount = valuable.value
			xaction.hold = 0 
			xaction.primary = valuable.origin.user.account
			xaction.save!
		end

		# :transfer
		event :transfer do
			transition :s_reserved => :s_transferred
		end
		before_transition :s_reserved => :s_transferred do |valuable, transition|
			# valuable.hold contains an amount to be released before the transfer
			xaction = Xaction.new(op: :transfer)
			xaction.amount = valuable.value
			xaction.hold = valuable.value
			xaction.primary = valuable.origin.user.account
			xaction.beneficiary = valuable.disposition.user.account
			xaction.save!
		end

		# :dispute
		event :dispute do
			transition :s_transferred => :s_reserved_4_dispute
		end
		before_transition :s_transferred => :s_reserved_4_dispute do |valuable, transition|
			xaction = Xaction.new(op: :reserve)
			xaction.amount = valuable.value * 2
			xaction.hold = 0 
			xaction.primary = valuable.disposition.user.account
			xaction.save!
		end

		# :adjudicate
		event :adjudicate do |evnt|
			transition :s_reserved_4_dispute => :s_transferred
		end
		before_transition :s_reserved_4_dispute => :s_transferred do |valuable, transition|
			for_plaintiff = transition.args[0][:for_plaintif]
			raise "event didn't specifiy for_plaintiff (true or false)" if for_plaintiff.nil?

			xaction = nil
			if for_plaintiff
				xaction = Xaction.new(op: :transfer)
				xaction.amount = valuable.value * 2
				xaction.hold = valuable.value * 2
				xaction.primary = valuable.disposition.user.account # now 2nd party's accnt
				xaction.beneficiary = valuable.origin.user.account # now 1st party's accnt
			else
				xaction = Xaction.new(op: :release)
				xaction.amount = valuable.value * 2
				xaction.hold = 0 
				xaction.primary = valuable.disposition.user.account # now 2nd party's accnt
			end
			xaction.save!
		end
	end

	#
	# Callbacks and helper classes
	#

	# Validations
	def self.validate_initial_state(transaction)
	    errors[:base] << "initial machine_state cannot be nil" if transaction.machine_state.nil?
	end

	def to_s
		"#{self.class} transaction=#{transaction}, value=#{value}, origin=#{origin}, disposition=#{disposition}, machine_state=#{machine_state}" 
	end

end
