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
# expressed relative to created_at (the current time), or relative to another Goal's
# created_at.  The syntax for this is Yaml:
# 
# { GoalCreateOffer: :never } =>		GoalOffer doesn't expire (it gets
#                                       disabled by GoalAccept)
#
# { GoalAcceptOffer: { GoalTenderOffer: "lambda {|g| g.advance(:hours => 48) }" } }
#                             =>		GoalAcceptOffer expires 48 hrs after
#                                       GoalTenderOffer#created_at
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

	has_many	:valuables, foreign_key: :contract_id, dependent: :destroy
	has_many	:artifacts, foreign_key: :contract_id, dependent: :destroy
	has_many	:goals, foreign_key: :contract_id, dependent: :destroy
	has_many	:parties, class_name: Party, foreign_key: :contract_id, dependent: :destroy

	# Validations

	#
	# Start the transaction.
	#
	def start()
		seed_transaction

		self.class.children().each do |goal_klass_sym|
			goal = model_instance(goal_klass_sym)
			goal = self.namespaced_class(goal_klass_sym).create!(:contract_id => self.id) \
				if goal.nil?
			goal.start()
		end
	end

	########################################################################################
	#
	# Basic class-based instance access methods.  Unlike the class-level methods,
	# which fetch symbols, these all fetch instance objects (Valuables, Partys, etc)
	#
	def model_instances(subclass_sym)
		subclass = self.namespaced_class(subclass_sym)
		klass = subclass.superclass
		ret = instance_eval("#{klass.to_s.downcase.pluralize}.all.select\
			{|r| r.class == #{subclass}}")
		ret
	end

	#
	# Use this when you expect exactly one
	#
	def model_instance(subclass_sym)
		values = model_instances(subclass_sym)
		raise "model_instances for '#{subclass_sym}' returned more than one" if values.count > 1
		values[0]
	end

	def latest_model_instance(subclass_sym)
		values = model_instances(subclass_sym)
		values[-1]
	end

	# 
	# Halt/abort the transaction by undo-ing and disabling each Goal that has executed.
	# Undo merely shuffles cash around (we don't destroy objects).
	# Each goal will only respond to, at most, one of these commands.
	#
	def reverse_completed_goals(caller)
		gls = self.goals.reverse
		gls.each do |goal|
			goal.undo() if goal != caller and goal.can_undo?
		end
	end

	def disable_active_goals(caller)
		gls = self.goals.reverse # reverse order of goals
		gls.each do |goal|
			goal.disable() if goal != caller and goal.can_provision?
		end
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
	def self.request_provisioning(goal_id, artifact_sym, initial_params)
		raise "Contract.request_provisioning must be overriden in subclass"
	end

	#
	# Get the active Goals available to a Party.  Pass party = :all to get
	# all active goals.
	#

	def active_goals(party)
		raise "party must be an instance of Party"\
			unless (party.instance_of?(Party) or party == :all)
		p_sym = self.class.const_to_symbol(party) unless party == :all
		gls = self.goals.all
		return nil if gls.nil? or gls.empty?
		ret = gls.select do |g|
			g.machine_state == "s_provisioning"\
				and\
			(party == :all) ? true : g.available_to.include?(p_sym)
		end
		ret
	end
	
	def active?
		active_goals(:all).nil? ? false : true
	end

	#
	# Returns either an Artifact, or the class of the Artifact that would be
	# created if the most recent Goal with (favorite_child? == true) succeeds.
	#
	def status_object
		gls = active_goals(:all)
		if gls.nil? or gls.empty? then
			return artifacts.last
		else
			return current_success_goal().class.artifact
		end
	end

	def current_success_goal
		gls = active_goals(:all)
		return nil if gls.nil?

		gls.each do |goal|
			return goal if goal.class.favorite_child?
		end
		return nil
	end

	def party_for(user)
		Party.find_by_user_id(user.id)
	end

	#
	# For a given user, return the list of parties aggregated from all their transactions
	#
	def self.transaction_associates(user)
		parties = Party.find(:all, :conditions => ["contract_id in (?)", user.contracts])
		parties
	end

	#
	# CONSTANTS, including those that the contract subclass must define 
	#

	FEES = Hash.new 
	FEES[:default] = Money.parse("$2")
	FEES[:CLPurchase] = Money.parse("$2")
	FEES[:ContractBet] = Money.parse("$2")

	def fees()
		contract = self.class.const_to_symbol(self)
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

	def self.children
		self::CHILDREN
	end

	#
	# This Artifact is used by first goal to get its expiration
	#
	def self.artifact
		self::ARTIFACT
	end

	#######################################################################
	#
	# Instance initialization
	#
	# Populate fields with defaults for new records

	def seed_transaction
		raise "Contract::Base must be subclassed" if self.class == Contract::Base
		self.save!
		
		# Create the party corresponding to admin
		admin = User.find(2); raise "administrator party not found" if !admin.admin
		pty = ::AdminParty.create!(:user_id => admin.id, contract_id: self.id) \
			if self.parties.select {|i| i.class == :AdminParty}[0].nil?
	end

	########################################################################################
	#
	# Contract validation.  Call this from spec code.
	#
	# Constants below must be defined in the Contract (subclass of Contract)
	#
	ContractConstantNames = [ \
		'VERSION',		'AUTHOR_EMAIL',	'CONTRACT_NAME',	'SUMMARY',
		'DEFAULT_BOND', 'TAGS', 'CHILDREN', 'ARTIFACT' \
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

end

########################################################################################
#
# Class to handle registration of Contracts 
# 
class ContractManager

	class << self
		attr_accessor :contracts
	end

	self.contracts = []

	def self.add_contract(klass)
		self.contracts << klass
	end

end
