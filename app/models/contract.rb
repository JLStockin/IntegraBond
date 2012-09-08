################################################################################
#
# Functionally, this is an abstract transaction class to support Rails single table
# inheritance (STI).
#
# An contract consists of these ActiveRecords:
#	Party -- maps a user to a contract role.
#	Valuable --	items to be exchanged which have a monetary value (which could be 0),
#					including bonds and system fees.  These are stateful to control
#					the transfer of real assets.
#	Artifacts -- notifications, requests, approvals, gps readings, documents, etc.  These
#		are stateless and always addressed to Goals.
#   Goals -- stateful control objects that manage Artifacts and advance the contract.
#
# Controllers create contracts and Artifacts.  Parties, Goals and Valuables are private
# to the model layer.
#
# When a Goal is created, a new statemachine is created.  The state machine may:
#	- de-activate old Goals
#   - create new Goals
#   - create and provision new Artifacts.
#	- ask a controller to message Party(s).
#
# As ActiveRecords, Goals already get 2 timestamps, created_at and updated_at.
# To function as goals, they need one more, an expires_at.  When the current time
# is passes expires_at, the goal's state becomes ":s_expired", and it is no longer
# active.
# 
# We need some way of expressing when goals should expire.  Goal expires_at can be
# expressed relative to created_at, or relative to another Goal's created_at.  The
# syntax for this is Yaml:
# 
# { GoalCreateOffer: { GoalOffer: :never } } =>		GoalOffer doesn't expire (it gets
#                                                   deactivated by GoalAccept)
#
# { GoalAccept: { GoalAccept: {:hours => 48} } } =>	GoalAccept expires 48 hrs after
#													GoalAccept's created_at
# Startup sequence: 
#
#	- user asks to look at contracts
#
#		contract_classes = Contract.contracts
#
#	- controller returns selection page to user
#	- ...
#	- user selects Contract
#	- controller creates contract 
#	- contract creates goal to manage offer, and starts its statemachine
#   - goal requests provisioning from the contract
#   - contract calls the appropriate controller on its behalf
#	- controller forms page based on goal's class and sends page to user
#	- ...
#	- user responds to controller with completed form
#	- controller calls goal via a callback, in this case,
#
#		goal.provision(*params)
#
#   - the goal creates a new artifact (the offer) and feeds the params to it,
#     has them validated, then creates new goal(s) and so on... 
#
#
module Contract; end

class Contract::Base < ActiveRecord::Base

	self.table_name = "contracts"

	#
	# ActiveRecord setup
	#
	include ActiveModel::Validations

	# Associations
	belongs_to	:originator, class_name: Party

	has_many	:valuables, foreign_key: :contract_id
	has_many	:artifacts, foreign_key: :contract_id
	has_many	:goals, foreign_key: :contract_id
	has_many	:parties, class_name: Party, foreign_key: :contract_id

	# Validations

	########################################################################################
	#
	# Basic class-based instance access methods.  Unlike the class-level methods,
	# which fetch symbols, these all fetch instance objects (Valuables, Partys, etc)
	#
	def model_instance(association, klass)
		klass = self.namespaced_const(klass)
		ret = association.all.select {|i| i.class == klass}
		raise "more than one instance of model type '#{klass}' found" if ret.count > 1 
		ret[0]
	end

	#
	# Start the transaction.
	#
	def start()
		seed_transaction
		klass = self.class.first_goal()
		goal = model_instance(goals, klass); raise "goal not yet instantiated" if goal.nil?
		goal.start()
	end

	# This is the system's party, who is party to all contracts and exists
	# to be paid.  The house is added to every subclass of Contract before
	# the subcontract gains control.
	#
	def house()
		admin = self.parties.first
		raise "administrator party not found" if admin.nil?
		admin
	end

	#
	# Forward model's request for data to appropriate controller.
	# This can be overriden by subclass if, for example, an existing Artifact has
	# the requested data.
	#
	def request_provisioning(artifact_klass, goal_id, initial_params)
		raise "Contract\#request_provisioning must be overriden in subclass"
	end

	#
	# CONSTANTS, including those that the contract subclass must define 
	#

	FEES = Hash.new 
	FEES[:default] = Money.parse("$2")
	FEES[:CLPurchase] = Money.parse("$2")
	FEES[:ContractBet] = Money.parse("$2")

	def self.fees()
		contract = self.const_to_symbol(self)
		return FEES[:default] unless !contract.nil? and FEES.keys.include?(contract) 
		ret = FEES[contract]
		ret
	end

	def self.bond_for(party)
		self::DEFAULT_BOND[party]
	end

	def self.version
		self::VERSION
	end

	def self.summary 
		self::SUMMARY
	end

	def self.author
		self::AUTHOR_EMAIL
	end

	def self.contract_name
		self::CONTRACT_NAME
	end

	def self.tags
		self::TAGS
	end

	def self.contains_tag?(tag)
		self::TAGS.include?(tag)
	end

	def self.first_goal
		self::FIRST_GOAL
	end

	#######################################################################
	#
	# Instance initialization
	#
	# Populate fields with defaults for new records

	def seed_transaction
		raise "contract class hierarchy improperly formed" if self.class == Contract::Base
		self.machine_state = :s_initial	# in case ever used
		self.save
		
		# Create the party corresponding to admin
		admin = User.find(2); raise "administrator party not found" if !admin.admin
		pty = ::AdminParty.create!(:user_id => admin.id, contract_id: self.id)

		# Create the first Goal
		goal_klass = self.class.first_goal()
		goal = self.namespaced_const(goal_klass).create!(:contract_id => self.id)
	end

	########################################################################################
	#
	# Contract validation.  Call this from spec code.
	#
	# Constants below must be defined in the Contract (subclass of Contract)
	#
	ContractConstantNames = [ \
		'VERSION',		'AUTHOR_EMAIL',	'CONTRACT_NAME',	'SUMMARY',
		'DEFAULT_BOND', 'TAGS' \
	]

	def self.valid_contract?()

		# Add validations for newly authored Contracts below
		self.check_contract_constants()
	end

	def self.check_contract_constants()
		raise "contract_constants_defined?() called on Contract itself!" \
			if self.class == Contract::Base 

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
		raise "invalid Offer class specified (or none)" unless self.offer.kind_of? Artifact
	end

	def self.verify_constants(constant_list)
		bad_constant = ""
		begin	
			constant_list.each do |constant_name|
				bad_constant = constant_name
				self.const_get(constant_name)
			end
			return true
		rescue NameError
			raise "#{self.class.to_s}: undefined constant #{bad_constant}"
		end
	end

	#
	# This is a means to verify protected methods during testing
	# TODO: add more tests...
	#
	def valid_contract?()
		(self.house.kind_of?(Party)) ? true : false
	end


	########################################################################################
	#
	# Loading of contracts, which must subclass Contract 
	#

	CONTRACT_DIRECTORY = "app/IBContracts"

	# This callback watches for creation of subclasses of Contract::Base registers them 
	#
	def self.inherited(contract)
		ContractManager.add_contract(contract)
		super
	end

	# This made not be needed.  Currently, it's not called.
	def self.load_contracts
		Dir[Rails.root.join CONTRACT_DIRECTORY, "*"].each do |d|
			Dir[Rails.root.join(CONTRACT_DIRECTORY, Pathname.new(d).basename, "*.rb")].each do |f|
				require 'f'
			end
		end
	end

end

########################################################################################
#
# ActiveRecord instantiates proxies which don't behave like normal classes.  ContractManager
# is a better-behaved static class that the model layer can depend on.
#

class ContractManager
	attr_accessor :params, :goal_id

	class << self
		attr_accessor :contracts
	end

	self.contracts = []

	def self.add_contract(klass)
		self.contracts << klass
	end

	#
	# Called by a controller to send data back to a Goal.
	#
	def self.provision(goal_id, params)
		goal = Goal.find(goal_id)
		goal.send(:provision, params)
	end
end

