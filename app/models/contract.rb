################################################################################
#
# Functionally, this is an abstract transaction class to support present and
# future Tranzaction types using Rails single table inheritance (STI).
#
#   "Tranzaction" -- (a transaction, but misspelled so as not to offend ActiveRecord) is
#		an abstraction used to represent an instantiation of a Contract.
#		It consists of these ActiveRecord objects:
#
#	Party -- specifies a contact for a user serving in a particular transactional role.
#	Contact -- a connection point to reach a User.  Users manage their own Contacts.
#	Valuable --	items to be exchanged which have a monetary value (which could be 0),
#					including bonds and system fees.  These are stateful to control
#					the transfer of real assets.
#	Artifacts -- notifications, requests, approvals, gps readings, documents, etc.  These
#		are stateless and always associated with Goals.  Artifacts fire actions within
#		Goals.  Some are immutable, while others can be edited.
#   Goals -- stateful, dynamically created control objects that manage the transaction.
#	Expirations -- expirations track time.  When their time is up, they create a special
#					class of Artifact. The Artifact then calls a method on the Goal.
#					Expirations are bound to Goals when Goals are created, allowing
#					them to accept configuration parameters for Goals not yet in existence.
#	Invitation -- Currently, an object linking a temporary Contact to a Party.  Users
#					follow Invitations to assume a Party, and thus a role in a Tranzaction.
#					Later, it may be subclassed for other purposes.
#	User
#	Account -- a User's bank account (holding money).
#	XAction -- a bank transaction that moves money around and creates a history.
#
# When a Goal is created, a new statemachine is created.  The state machine may:
#	- de-activate old Goals
#   - create new Goals
#   - request that an Artifact be created
#   - request that an Expiration be created
#
class Contract < ActiveRecord::Base

	self.table_name = "tranzactions"

	#
	# ActiveRecord setup
	#
	include ActiveModel::Validations

	# Associations created through controller 
	has_many	:parties, class_name: Party, foreign_key: :tranzaction_id,
					dependent: :destroy, autosave: true
	has_many	:valuables, foreign_key: :tranzaction_id, dependent: :destroy, autosave: true
	has_many	:artifacts, foreign_key: :tranzaction_id, dependent: :destroy, autosave: true

	has_many	:self_expirations, as: :owner, class_name: Expiration, dependent: :destroy
	has_many	:goal_expirations, through: :goals, source: :expiration , as: :owner

	accepts_nested_attributes_for :parties
	accepts_nested_attributes_for :valuables

	# Associations created by the Model itself
	has_many	:goals, foreign_key: :tranzaction_id, dependent: :destroy
	has_one		:originator, class_name: Party, foreign_key: :originator_id

	attr_accessible :originator

	def expirations
		self_expirations + goal_expirations
	end

	#
	# Start the Tranzaction state_machine(s)
	#
	def start()
		seed_tranzaction()

		self.class.children().each do |goal_klass_sym|
			goal = model_instance(goal_klass_sym)
			goal = self.namespaced_class(goal_klass_sym).new() if goal.nil?
			goal.tranzaction_id = self.id
			goal.save!
			goal.start(false, true)	# Don't provision, do expire  
		end
	end

	def seed_tranzaction() 
		raise "Contract must be subclassed" if self.class == Contract

		# Create the party corresponding to admin
		admin = User.find(2); raise "administrator party not found" if !admin.admin
		::AdminParty.create!(tranzaction_id: self.id, contact_id: admin.contacts[0].id)

	end

	########################################################################################
	#
	# Basic class-based instance access methods.  Unlike the class-level methods,
	# which fetch symbols, these all fetch instance objects (Valuables, Partys, etc)
	#
	# Relies on their being a plural getter for that class on the Contract subclass
	# (the Tranzaction).  Notice that we have to wend our way through the class
	# hierarchy to find the basic model class.
	#
	MODELS = [\
		Party, Artifact, Valuable, Contact, Contract,
		Account, Goal, User, Expiration, Xaction, Invitation\
	]
	MAX_HIERARCHY_DEPTH = 5

	def model_instances(subclass_sym)
		sub_class = self.namespaced_class(subclass_sym)
		table_class = sub_class.superclass()
		hierarchy_depth = 0
		while !MODELS.include?(table_class) and hierarchy_depth < MAX_HIERARCHY_DEPTH do
			table_class = table_class.superclass
			hierarchy_depth += 1
		end

		raise "#{subclass_sym} not found in class hierarchy"\
			if hierarchy_depth == MAX_HIERARCHY_DEPTH
		instance_eval("#{table_class.to_s.downcase.pluralize}.select\
			{|r| r.class == #{sub_class}}")
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

	########################################################################################
	#
	# Create accessors for associations that exist as one-to-many on Contract, but one-to-one
	# for the Contract subclass.  Name the accessors after the association's subclass.
	#
	# Example:
	#	class Party < ActiveRecord::Base
	#		...
	#	end
	#
	#	class Party1 < Party
	#		...
	#	end
	#
	#	class Contract < ActiveRecord::Base
	#		has_many Partys
	#		...
	#
	#	class ContractBet < Contract
	#		assoc_accessor :Party1		# <----------- we get methods party1() and party1=(val)
	#									# These methods either fetch the existing Party of this
	#									# type, or create it.
	#		...
	#		party1.contact = EmailContact.new(tranzaction_id: tranzaction.id, ...)
	#
	def self.assoc_accessor(klass)
		assoc_name = klass.to_s.underscore()
		getter = "#{assoc_name}".to_sym
		setter = "#{assoc_name}=".to_sym
		var = "@#{assoc_name}".to_sym

		define_method(getter) do
			ret = instance_variable_get(var) || self.model_instance(klass)
			ret.nil? ? self.namespaced_class(klass).new() : ret
		end

		define_method(setter) do |value|
			instance_variable_set(var, value)
		end
	end

	#
	# Given a model object classname, obtain the reader (as defined above) for it. 
	#
	def classname_to_getter(class_name)
		self.send(class_name.to_s.underscore)
	end

	#
	# This method allows us to lump several classes into a single file.
	# It takes care of loading the classes that are "hidden" from Rails.
	#
	def self.register_dependencies()
		self::DEPENDENCIES.each { |file| require file }
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

	# This is the system's party, who is party to all transactions and exists
	# to be paid.  The house is added to every subclass of Contract before
	# the subclass gains control.
	#
	def house()
		admin = self.parties.first
		raise "administrator party not found" if admin.nil?
		admin
	end

	#
	# Get the active Goals available to a Party.  Pass party = :all to get
	# all active goals.
	#
	def active_goals(party)
		raise "party must be an instance of Party"\
			unless (party.is_a?(Party) or party == :all)
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
		self.machine_state == :completed? ? true : false
		# active_goals(:all).nil? ? false : true
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

	#
	# UNTESTED!
	# For a given user, return the list of tranzactions involving them
	#
	def self.tranzactions_for(usr)
		Contract.joins{parties.contact}.where{contracts.parties.contacts.user_id == usr.id}
	end

	#
	# UNTESTED!
	# For a given user, return the list of users aggregated from that user's transactions
	#
	def self.associates_for(usr)
		user_tranzactions =\
			Contract.joins{parties.contact.user}.where{parties.contact.user_id == usr.id}
		User.joins{contacts.parties}\
			.where{user.parties.tranzaction_id.in(user_tranzactions.select{id})}.uniq
	end

	#
	# UNTESTED!
	# For a given user, return the list of Goals obtained through Party, plus Goals for
	# any tranzactions recently authored, which don't yet have Parties.
	#
	def self.tranzaction_goals(usr)
		Goal.joins{tranzaction.parties.contact}\
			.where{ (tranzaction.parties.contact.user_id == usr.id) \
				| (tranzaction.originator_id == usr.id) }
	end

	#
	# Create a new Tranzaction (Contract instance) 
	# UNTESTED!
	#
	def self.create_tranzaction(contract_class, current_user)
		tranz = contract_class.create!()
		tranz.create_parties(current_user)
		tranz.create_valuables()
		tranz.create_expirations()
		tranz.create_artifact_for(tranz)
		tranz
	end

	#
	# UNTESTED!
	# :creator can be a Goal instance or an Expiration 
	# 
	def create_artifact_for(type_provider, params = nil)
		goal = nil
		artifact = nil
		artifact_type = type_provider.class.artifact()

		if type_provider.is_a?(Goal) then
			goal = type_provider 
		elsif type_provider.is_a?(Expiration)
			goal = type_provider.goal 
		elsif type_provider.is_a?(Contract)
			goal = nil 
		else
			raise "bad type_provider"
		end

		unless artifact_type.nil? then
			artifact_class = self.namespaced_class(artifact_type)
			artifact = artifact_class.new()
			artifact.mass_assign_params(params.nil? ? artifact_class.params : params)
			self.artifacts << artifact
			goal.artifact = artifact unless goal.nil?
			artifact.save!
		end
		return artifact

	end

	#
	# UNTESTED!
	# 
	def create_parties(current_user)
		self.class.party_roster.each_with_index do |party_sym, idx|
			party = self.namespaced_class(party_sym).new()
			party.tranzaction = self

			# TODO: use a default contact instead of contacts[0]
			if (idx == 0) then
				party.contact = current_user.contacts[0]
				party.contact_strategy = nil 
			else
				contact = EmailContact.new()
				contact.contact_data = "JoeBlow@example.com"
				contact.user = nil
				party.contact = contact
				party.contact_strategy = Contact::CONTACT_METHODS[0]
			end
			self.parties << party 
			party.save!
		end
		return self.parties 
	end

	#
	# Create a Tranzaction's Valuables
	# UNTESTED!
	#
	def create_valuables(params = nil)
		self.class.valuables.each do |valuable_sym|
			klass = self.namespaced_class(valuable_sym)
			valuable = klass.new 
			valuable.tranzaction = self
			if (params.nil?) then
				valuable.value = klass::VALUE 
			else
				valuable.value = params[index][:value]
				stripped_params = params[index].remove(:value)
				valuable.mass_assign_params(stripped_params)
			end
			owner = klass::OWNER
			valuable.origin = self.model_instance(owner)
			valuable.disposition = valuable.origin
			self.valuables << valuable
			valuable.save!
		end
		return self.valuables 
	end

	#
	# Create a Tranzaction's Expirations
	# UNTESTED!
	#
	def create_expirations(params = nil)
		self.class.expirations.each_with_index do |sym, index|
			klass = self.namespaced_class(sym)
			expiration = klass.new 
			expiration.offset = params.nil? ? klass::DEFAULT_OFFSET : params[:offset]
			expiration.offset_units = params.nil? \
				? klass::DEFAULT_OFFSET_UNITS : params[:offset_units]
			expiration.owner = self
			expiration.save!
		end
	end

	#
	# Tell a client that they should fetch changed_path, because data along
	# that path has changed, or something needs input from the user.
	#
	def server_push(party, changed_path)

	end

	#
	# Flash a message to the indicated Party.  Message should be obtained
	# from ModelDescriptior.  Note that we can use the regular :flash data structure
	# during the normal request/response cycle; this is just for server push.
	#
	def flash_party(party, message)
		Rails.logger.info("#{party.contact.inspect} sent '#{message}'")
	end

	#
	# Push a request to provision (create an Artifact)
	#
	# If request is successful, goal will be called back on method
	# provision().
	#
	def request_provision(goal)
		goal.class.available_to().each do |party_sym|
			party_class = self.namespaced_class(party_sym)	
			party = self.model_instance(party_sym)
			Rails.logger.info("server push: party = #{party.inspect}, goal = #{goal.inspect}")
			server_push( party, self.artifact_path_for(goal) ) \
				unless goal.artifact().nil? or party.nil? or provision == false
		end
	end

	#
	# Bind to an existing Expiration object if it exists.
	#
	# If the expiration time arrives, goal will be called back on the method 
	# on_expire().
	#
	def request_expiration(goal)
		expiration_sym = goal.class.expiration()
		unless expiration_sym.nil? then
			expiration = self.model_instance(expiration_sym)
			raise "Didn't find Expiration object of type '#{expiration_sym}'" if expiration.nil?
			expiration.bind(goal)
		end
	end

	def artifact_path_for(goal)
		return "goals/#{goal.id}/artifacts/new"
	end

	########################################################################################
	#
	# class accessors for constants
	#

	def title()
		return self.title if self.methods.include? :title
		self.class.contract_name
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

	def self.party_roster
		self::PARTY_ROSTER
	end

	def self.valuables
		self::VALUABLES
	end

	def self.expirations
		self::EXPIRATIONS
	end

	def self.artifact
		self::ARTIFACT
	end

	########################################################################################
	#
	# Setup state_machine for collecting data from Party initiating Tranzaction
	#
	# Contract must define the following constants for the state machine:
	# WIZARD_STEPS, PAGE_OBJECTS, FORWARD_TRANSITIONS, # REVERSE_TRANSITIONS, DEPENDENCIES

	def self.first_step()
		return self::WIZARD_STEPS.first 
	end

	def first_step?()
		self.wizard_step == self.class::WIZARD_STEPS.first.to_s
	end
	def final_step?()
		self.wizard_step == self.class::WIZARD_STEPS.last.to_s
	end

	def self.inject_page_wizard()
		class_eval do
			StateMachine::Machine.new(self, attribute: :wizard_step)
			self.state_machine.initial_state = self.first_step() 

			# Forward steps	<----- :next_step, :can_next_step?, :resume, :can_resume?
			self::FORWARD_TRANSITIONS.each do |transitions|
				self.state_machine.transition(transitions)
			end

			# Reverse steps <----- :previous_step, can_previous_step?
			self::REVERSE_TRANSITIONS.each do |transitions|
				self.state_machine.transition(transitions)
			end
		end
	end

	# Called when we are leaving a wizard page.  Save the objects.
	#
	def save_page_objects()
		status = true
		class_names = self.class::PAGE_OBJECTS[self.wizard_step.to_sym]
		class_names.each do |class_name|
			status = status and self.classname_to_getter(class_name).save()
		end unless class_names.nil?
		status
	end

	########################################################################################
	#
	# Contract validation.  Call this from spec code.
	#
	# Constants below must be defined in the Contract (subclass of Contract)
	#
	def self.valid_contract?()
		# Add validations for newly authored Contracts below
		self.check_contract_constants()
	end

	def self.check_contract_constants()
		raise "contract_constants_defined?() called on Contract itself!" \
			if self.class == Contract

		bad_constant = ""
		begin	
			CONTRACT_CONSTANT_NAMES.each do |constant_name|
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

	CONTRACT_CONSTANT_NAMES = [ \
		'VERSION', 'VALUABLES', 'AUTHOR_EMAIL', 'TAGS', 'EXPIRATIONS',
		'CHILDREN', 'ARTIFACT', 'PARTY_ROSTER', 'WIZARD_STEPS', 'PAGE_OBJECTS',
		'CONTRACT_NAME', 'FORWARD_TRANSITIONS', 'REVERSE_TRANSITIONS', 'DEPENDENCIES'\
	]

	########################################################################################
	#
	# Loading of contracts, which must subclass Contract 
	#

	CONTRACT_DIRECTORY = "app/contracts"

	# This callback watches for creation of subclasses of Contract and registers them 
	#
	def self.inherited(contract)
		super
		ContractManager.add_contract(contract)
	end
end

########################################################################################
#
# Class to handle registration of Contracts.  Contracts are code that must be checked into
#	the site's source tree.
# 
class ContractManager

	class << self
		attr_accessor :contracts
	end

	self.contracts = []

	def self.add_contract(klass)
		self.contracts << klass
	end

	def self.register_contracts()
		Dir[Rails.root.join('app/contracts', '*')].each do |prj_dir|
			Dir[File.join(prj_dir, 'contract_*.rb')].each do |file|
				contract_name = file.split('/')[-2]
				file = File.join(	"contracts/#{contract_name}",
									File.basename(file.chomp( File.extname(file) )))
				require file
			end
		end
	end

	register_contracts()
end
