#require 'state_machine'

class Valuable < ActiveRecord::Base
	extend Provisionable

	raise "you must derive a class from Valuable" if self.class == Valuable

	#
	# ActiveRecord setup
	#
	include ActiveModel::Validations

	# Monetization
	monetize		:value_cents

	# Accessibility
	#attr_accessible :origin_id, :disposition_id, :value

	# Associations
	belongs_to	:tranzaction, class_name: Contract, foreign_key: :tranzaction_id
	belongs_to	:origin, class_name: Party, foreign_key: :origin_id
	belongs_to	:disposition, class_name: Party, foreign_key: :disposition_id 

	# Validations
	validates	:tranzaction, presence: true

	validates	:origin_id, presence: true
	validates	:disposition_id, presence: true
	validates	:value_cents, numericality: true

	#######################################################################
	#
	# Instance initialization
	#

	# Populate fields with defaults for new records
	class ValuableInitializer
		def self.before_create(record)
			record.initialize_valuable
		end
	end

	before_create		ValuableInitializer

	def initialize_valuable
		self.value_cents ||= 0
	end

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
			if valuable.class.asset?() then
				true
			else
				xaction = Xaction.new(op: :reserve)
				xaction.amount = valuable.value
				xaction.hold = 0 
				xaction.primary = valuable.origin.contact.user.account
				xaction.save
			end
		end

		# :release
		event :release do
			transition :s_reserved => :s_initial
		end
		before_transition :s_reserved => :s_initial do |valuable, transition|
			if valuable.class.asset?() then
				true
			else
				xaction = Xaction.new(op: :release)
				xaction.amount = valuable.value
				xaction.hold = 0 
				xaction.primary = valuable.origin.contact.user.account
				xaction.save
			end
		end

		# :transfer
		event :transfer do
			transition :s_reserved => :s_transferred
		end
		before_transition :s_reserved => :s_transferred do |valuable, transition|
			if valuable.class.asset?() then
				true
			else
				# valuable.hold contains an amount to be released before the transfer
				xaction = Xaction.new(op: :transfer)
				xaction.amount = valuable.value
				xaction.hold = valuable.value
				xaction.primary = valuable.origin.contact.user.account
				xaction.beneficiary = valuable.disposition.contact.user.account
				xaction.save
			end
		end

		# :dispute
		event :dispute do
			transition :s_transferred => :s_reserved_4_dispute
		end
		before_transition :s_transferred => :s_reserved_4_dispute do |valuable, transition|
			if valuable.class.asset?() then
				true
			else
				xaction = Xaction.new(op: :reserve)
				xaction.amount = valuable.value * 2
				xaction.hold = 0 
				xaction.primary = valuable.disposition.contact.user.account
				xaction.save
			end
		end

		# :adjudicate
		event :adjudicate do |evnt|
			transition :s_reserved_4_dispute => :s_transferred
		end
		before_transition :s_reserved_4_dispute => :s_transferred do |valuable, transition|
			if valuable.class.asset?() then
				true
			else
				for_plaintiff = transition.args[0][:for_plaintif]
				raise "event didn't specifiy for_plaintiff (true or false)" if for_plaintiff.nil?

				xaction = nil
				if for_plaintiff
					xaction = Xaction.new(op: :transfer)
					xaction.amount = valuable.value * 2
					xaction.hold = valuable.value * 2
					# now 2nd party's accnt
					xaction.primary = valuable.disposition.contact.user.account
					# now 1st party's accnt
					xaction.beneficiary = valuable.origin.contact.user.account
				else
					xaction = Xaction.new(op: :release)
					xaction.amount = valuable.value * 2
					xaction.hold = 0
					# now 2nd party's accnt
					xaction.primary = valuable.disposition.contact.user.account
				end
				xaction.save
			end
		end
	end

	def self.sufficient_funds?(*valuables)
		amnt = MZERO  
		party_id = valuables[0].origin_id
		valuables.each do |valuable|
			raise "valuables belong to different users" unless valuable.origin_id = party_id
			amnt += valuable.value unless valuable.class.asset?()
		end
		valuables[0].origin.contact.user.account.sufficient_funds?(amnt)
	end

	#
	# Assets don't get reserved or debited
	#
	def self.asset?
		self::ASSET
	end

	# PARAMS must be specified in subclass

	#
	# Callbacks and helper classes
	#

	# Validations
	def self.validate_initial_state(tranzaction)
	end

end
