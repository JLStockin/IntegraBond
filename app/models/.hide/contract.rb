################################################################################
#
# Functionally, this is an abstract transaction class to support Rails single table
# inheritance (STI).
#
# A transaction consists of these ActiveRecords:
#	Parties -- maps a user to a transaction role.
#	Valuables --	items to be exchanged which have a monetary value (which could be 0),
#					including bonds and system fees.  These are stateful to control
#					the transfer of real assets.
#	Artifacts -- notifications, requests, approvals, gps readings, documents, etc.  These
#		are stateless and always addressed to Goals.
#   Goals -- stateful objects that advance the transaction.
#
# Controllers create transactions and Artifacts.  Parties, Goals and Valuables are private
# to the model layer.
#
# When a Goal is created, a new statemachine is created.  The state machine may:
#	- de-activate old Goals
#   - create new Goals
#   - respond to the arrival of new Artifacts.
#	- ask a controller to message Party(s).
#
# As ActiveRecords, Goals already get 2 timestamps, created_at and updated_at.
# To function as goals, they need one more, an expires_at.  If the current time
# is less than expires_at, then the goal is active.
# 
# We need some way of expressing when goals should expire.  Goal expires_at can be
# expressed relative to created_at, or relative to another Goal's created_at.  The
# syntax for this is Yaml:
# 
# { meet: { rel: {setappt: {:hours => 24}} } } => appointment is 24 hrs after
#												  :setappt Goal's created_at
#
# { accept: { rel: {list: {:hours => 48}} } } => listing expires 48 hrs after :list
#												 Goal's created_at
# Bootstrapping the transaction --
#
# To initiate a transaction:
#
#	trans = MyContract.create(...)
#
#
module Contract; end

class Contract::Base < ActiveRecord::Base

	#
	# ActiveRecord setup
	#
	include ActiveModel::Validations

	# Accessibilty
	#attr_reader :type ???
	attr_reader :id

	# Associations
	belongs_to	:author, :class_name => :User
	has_many	:parties, class_name: :Party 
	has_many	:valuables
	has_many	:artifacts
	has_many	:goals

	########################################################################################
	#
	# Basic instance access methods 
	#
	def valuable(klass)
		raise "invalid valuable type '#{klass}'" unless VALUABLES.include? klass 
		klass = class_from_symbol(klass)
		ret = valuables.select {|v| v.class == klass}
		raise "more than one valuable of type '#{klass}' found" if ret.count > 1 
		ret
	end

	def party(klass)
		raise "invalid party type '#{klass}'" unless PARTIES.include? klass 
		klass = klass.instance_of?(Symbol) ? Object.const_get(klass) : klass
		ret = parties.select {|p| p.klass == klass}
		raise "more than one party of type '#{klass}' found" if ret.count > 1 
		ret
	end

	def artifact(klass)
		raise "invalid artifact type '#{klass}'" unless ARTIFACTS.include? klass 
		klass = klass.instance_of?(Symbol) ? Object.const_get(klass) : klass
		ret = artifacts.select {|a| a.class == klass}
		raise "more than one artifact of type '#{klass}' found" if ret.count > 1 
		ret
	end

	#
	# Notify relevant Goals about the arrival of a new Artifact
	#
	def send_event(artifact)
		if (object.is_a?(Artifact)) then
			goals.each do |goal|
				goal.send_event(object) if goal.active? \
					and goal.state_events.include?(object.to_event())
			end
		else
			raise "attempted to send #{object.class} to a Goal"
		end
	end

	#
	# CONSTANTS, including those that the transaction subclass must define 
	#

	FEES = Hash.new 
	FEES[:default] = Money.parse("$2")
	FEES[:CLPurchase] = Money.parse("$2")
	FEES[:ContractBet] = Money.parse("$2")

	def self.fees()
		contract = self.unqualified_const(self).to_sym
		return FEES[:default] unless !contract.nil? and FEES.keys.include?(contract) 
		FEES[contract]
	end

	def self.bond(party)
		self.class::DEFAULT_BOND[party]
	end

	def self.version
		self.class::VERSION
	end

	def self.summary 
		self.class::SUMMARY
	end

	def self.author
		self.class::AUTHOR_EMAIL
	end

	def self.contract_name
		self.class::CONTRACT_NAME
	end

	def self.valuables
		self.class::VALUABLES
	end

	def self.parties
		self.class:PARTIES
	end

	def self.artifacts
		self.class:ARTIFACTS
	end

	def self.goals
		self.class:GOALS
	end

	def self.offer
		self.class:ARTIFACTS[0]
	end

	#######################################################################
	#
	# Instance initialization
	#

	# Populate fields with defaults for new records
	class ContractInitializer
		def after_initialize(record)
			record.send(:set_defaults)	# bypass private
		end

		def before_create(record)
			record.send(:set_defaults)	# bypass private
		end
	end

	def set_defaults
		raise "transaction class hierarchy improperly formed" if self.class == Contract::Base
		self._data									||= {}
		#self.type									||= self.class.to_s

		# Make sure the administrator is party to all transactions
		party_admin = Party.find_by_id(2)
		raise "admin party not found" if party_admin.type = PartyAdmin.to_s 
		party_admin.transaction_id = self.id
		self.parties << party_admin
	end

	after_initialize	ContractInitializer.new	
	after_create		ContractInitializer.new	

	########################################################################################
	#
	# Contract validation.  Call this from spec code.
	#
	# Constants below must be defined in the Contract (subclass of Contract)
	#
	ContractConstantNames = %W/VERSION AUTHOR_EMAIL CONTRACT_NAME SUMMARY \
								PARTIES ARTIFACTS GOALS VALUABLES DEFAULT_BOND/

	def self.validate_contract()

		# Add validations for newly authored Contracts below
		self.check_contract_constants()
	end

	def self.check_contract_constants()
		raise "contract_constants_defined?() called on Contract itself!" \
			if self.class == Contract::Base 

		raise "invalid Offer class specified (or none)" if self.offer.instance_of? Offer

		bad_constant = ""
		begin	
			ContractConstantNames.each do |constant_name|
				bad_constant = constant_name
				self.const_get(constant_name)
			end
			return true
		rescue NameError => error 
			raise "#{self.class.to_s}: undefined constant #{bad_constant}"
		end
	end

	# Validations
	# !!!!!!!! TODO: Add validation for machine state: ask machine for all states
	def self.validate_initial_state(transaction)
		errors[:base] << "initial machine_state cannot be nil" if transaction.machine_state.nil?
	end

	#######################################################################################
	#
	# Utilities
	#

	def qualified_const(klass)
		clean = klass.to_s.split ':'
		klass = clean[-1]

		klass_path = self.class.to_s.split('::').select {|seg| seg != ""}
		(klass_path.join('::') + '::' + klass).constantize
	end

	def unqualified_const(klass)
		klass.to_s.split(':')[-1].split('::')[-1]
	end

	def valid_constant?(name)
		begin
			qualified_const name
			return true
		rescue NameError
			false
		end
	end

	########################################################################################
	#
	# Loading of contracts, which must subclasse Contract 
	#

	CONTRACT_DIRECTORY = "app/models/IBContracts"

	class << self 
		attr_accessor :contracts
	end
	self.contracts = []

	# This callback watches for creation of subclasses of Contract::Base and registers them
	def self.inherited(contract)
		self.contracts << contract if self.valid_contract
	end

	def self.load_contracts
		Dir[Rails.root.join CONTRACT_DIRECTORY, "*"].each do |d|
			Dir[Rails.root.join(CONTRACT_DIRECTORY, Pathname.new(d).basename, "*.rb")].each do |f|
				require 'f'
			end
		end
	end

	self.load_contracts()
end
