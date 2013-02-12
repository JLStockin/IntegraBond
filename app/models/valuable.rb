
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
				account = valuable.origin.contact.user.account
				account.reserve(valuable.value)
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
				account = valuable.origin.contact.user.account
				account.clear(valuable.value)
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
				primary = valuable.origin.contact.user.account
				beneficiary = valuable.disposition.contact.user.account
				Account.transfer(valuable.value, primary, beneficiary, valuable.value)
			end
		end

		# :dispute -- plaintiff is the Valuable's origin; defendant is
		# Valuable's disposition
		event :dispute do
			transition :s_transferred => :s_reserved_4_dispute
		end
		before_transition :s_transferred => :s_reserved_4_dispute do |valuable, transition|
			if valuable.class.asset?() then
				true
			else
				account = valuable.disposition.contact.user.account
				account.reserve(valuable.value)
			end
		end

		# :adjudicate -- see above for meaning of plaintiff
		event :adjudicate do
			transition :s_reserved_4_dispute => :s_transferred
		end
		before_transition :s_reserved_4_dispute => :s_transferred do |valuable, transition|
			if valuable.class.asset?() then
				true
			else
				for_plaintiff = transition.args[0][:for_plaintif]
				raise "event didn't specifiy for_plaintiff (true or false)" if for_plaintiff.nil?

				if for_plaintiff
					primary = valuable.disposition.contact.user.account
					beneficiary = valuable.origin.contact.user.account
					Account.transfer(valuable.value, primary, beneficiary, valuable.value)
				else
					primary = valuable.disposition.contact.user.account
					beneficiary = nil
					primary.clear(valuable.value)
				end
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

	def self.owner
		self::OWNER
	end

	def self.value
		self::VALUE
	end

	CONSTANT_LIST = [
		'ASSET', 'OWNER', 'VALUE'
	]

	# PARAMS must be specified in subclass

	#
	# Callbacks and helper classes
	#

	# Validations
	def self.validate_initial_state(tranzaction)
	end

	def value 
		Money.new(value_cents, currency)
	end

	def value=(value)
		value = Money.parse(value) if value.instance_of?(String)
		write_attribute(:value_cents, value.cents)
		write_attribute(:currency, value.currency_as_string)
	end

end
