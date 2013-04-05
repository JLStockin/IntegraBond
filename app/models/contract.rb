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
#					Later, it may be subclassed for other purposes such as coupons.
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
# To get the whole process started, Contract has some basic properties of a Goal
# (CHILDREN (Goals), ARTIFACT, and EXPIRATIONS).
#
require 'net/http'

class Contract < ActiveRecord::Base

	self.table_name = "tranzactions"

	#
	# ActiveRecord setup
	#
	include ActiveModel::Validations

	has_many	:parties, class_name: Party, foreign_key: :tranzaction_id,
					dependent: :destroy, autosave: true
	has_many	:valuables, foreign_key: :tranzaction_id, dependent: :destroy, autosave: true
	has_many	:artifacts, foreign_key: :tranzaction_id, dependent: :destroy, autosave: true

	accepts_nested_attributes_for :parties
	accepts_nested_attributes_for :valuables

	# Associations created by the Model itself
	has_many	:goals, class_name: Goal, foreign_key: :tranzaction_id,
					dependent: :destroy, autosave: true
	has_one		:originator, class_name: Party, foreign_key: :originator_id

	has_many	:expirations, foreign_key: :tranzaction_id, dependent: :destroy

	attr_accessible :originator

	#
	# Start the Tranzaction's Goal(s)' state_machines
	#
	def start(delay_starting_goals = false)
		seed_tranzaction()

		self.class.children().each do |goal_klass_sym|
			goal = model_instance(goal_klass_sym)
			goal = self.namespaced_class(goal_klass_sym).new() if goal.nil?
			self.goals << goal
			goal.save!

			# delay_starting_goals is for debugging
			goal.start!() unless delay_starting_goals
		end
	end

	def seed_tranzaction() 
		raise "Contract must be subclassed" if self.class == Contract

		# Create the party corresponding to admin
		admin = User.where{users.admin == true}
		raise "administrator party not found" if admin.count == 0
		raise "more than one administrator found!" if admin.count > 1

		admin = admin.first
		raise "administrator has no Contacts" if admin.contacts.nil? or admin.contacts.empty?
		AdminParty.create!(tranzaction_id: self.id, contact_id: admin.contacts[0].id)

	end

	def admin_party()
		self.parties.where{self.type == "AdminParty"}.first
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
	def model_instances(subclass_sym)
		raise "model_instances called for nil symbol" if subclass_sym.nil?

		table_class = table_class(subclass_sym)
		subclass = self.namespaced_class(subclass_sym)
		cmd = "self.#{table_class.to_s.pluralize.downcase}.where{self.type == #{subclass}.to_s}"
		self.instance_eval(cmd)
	end

	#
	# Use this when you expect exactly one
	#
	def model_instance(subclass_sym)
		values = model_instances(subclass_sym)
		raise "model_instances for '#{subclass_sym}' returned more than one" if values.count > 1
		values[0]
	end

	#
	# Assumes that instances are ordered in DB by creation time
	#
	def latest_model_instance(subclass_sym)
		values = model_instances(subclass_sym)
		values[-1]
	end

	#
	# Given a symbol representing an ActiveRecord subclass, walk up a subclass
	# hierarchy until we hit a recognized model class; return that class
	#
	MAX_HIERARCHY_DEPTH = 5
	TABLE_MODELS = [
		Party, Artifact, Valuable, Contact, Contract,
		Account, Goal, User, Expiration, Xaction, Invitation
	]

	def table_class(subclass_sym)
		subclass = self.namespaced_class(subclass_sym)
		raise "can't find class '#{subclass_sym}'" if subclass.nil?

		table_class = subclass.superclass()
		hierarchy_depth = 0
		while !TABLE_MODELS.include?(table_class) and hierarchy_depth < MAX_HIERARCHY_DEPTH do
			table_class = table_class.superclass
			hierarchy_depth += 1
		end

		raise "#{subclass_sym} not found in class hierarchy"\
			if hierarchy_depth == MAX_HIERARCHY_DEPTH
		table_class
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
		var = "@#{assoc_name}".to_sym

		define_method(getter) do
			ret = instance_variable_get(var)
			if (ret.nil?) then
				ret = self.model_instance(klass)
				ret = self.instance_variable_set(var, ret) unless ret.nil?
			end
			return ret 
		end

	end

	#
	# This method allows us to lump several classes into a single file.
	# It takes care of loading the classes that are "hidden" from Rails.
	#
	def self.register_dependencies()
		self::DEPENDENCIES.each do |file|
			dep = (file.split('/').map!{|seg| seg.to_s.camelize}).join('::').to_s.constantize
		end
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
		admin = self.parties.where{type == AdminParty.to_s}.first
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
		p_sym = ActiveRecord::Base.const_to_symbol(party.class) unless party == :all
		gls = self.goals.all
		return nil if gls.nil? or gls.empty?
		ret = gls.select do |g|
			g.state == "s_provisioning"\
				and\
			(party == :all) ? true : g.class.available_to.include?(p_sym)
		end
		ret
	end
	
	# Utilities to manage Parties
	#
	def party_for(user)
		parties = self.parties.joins{contact}.where{contact.user_id == user.id}
		parties.first
	end

	def symbol_to_party(symbol)
		self.model_instance(symbol)
	end

	def has_active_goals?
		goals = self.active_goals(:all)
		goals and !goals.empty?
	end

	def editing?
		!self.final_step?
	end

	def latest_artifact 
		return artifacts.last
	end

	#
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
	#
	def self.create_tranzaction(contract_class, current_user)
		raise "bad contract class" if contract_class.nil?
		raise "no current user" if current_user.nil?
		tranz = contract_class.create!()
		tranz.create_parties(current_user)
		tranz.create_valuables()
		tranz.create_expirations()
		tranz.create_artifact_for(tranz, tranz.party_for(current_user))
		tranz
	end

	#
	# Artifact.origin and any params can be set:
	# 	1) by the controller (e.g, from current_user() or via a hidden field in the form
	#   2) by a before_save() callback in the model (if not dependent on current_user()) 
	#
	# instance can be a Tranzaction, Goal, or Expiration
	# 
	def create_artifact_for(instance, party)
		artifact = build_artifact_for(instance, party)
		if artifact then
			artifact.save!
			artifact.fire_goal()
		end
		return artifact
	end

	def build_artifact_for(instance, party)
		artifact = nil
		artifact_type = instance.class.artifact()

		unless artifact_type.nil? then
			artifact_class = self.namespaced_class(artifact_type)
			artifact = artifact_class.new()
			artifact.tranzaction = self
			artifact.goal = goal_for(instance)
			artifact.origin = party
			artifact.subclass_init(instance, party) if artifact.methods.include? :subclass_init
		end
		artifact
	end

	def goal_for(o)
		goal = nil
		if o.is_a?(Goal) then
			goal = o
		elsif o.is_a?(Expiration)
			goal = o.goal 
		end
		return goal
	end

	#
	# Create a Tranzaction's Part[ies]
	#
	def create_parties(current_user)
		self.class.party_roster.each_with_index do |party_sym, idx|
			if (idx == 0) then
				create_first_party(party_sym, current_user)
			else
				create_party(party_sym)
			end
		end
		return self.parties 
	end

	# TODO: use a default contact instead of contacts[0]
	def create_first_party(party_sym, current_user)
		party = self.namespaced_class(party_sym).new()
		party.contact = current_user.contacts[0]
		party.contact_strategy = nil 
		self.parties << party	# implicit party.save()
		party
	end

	def create_party(party_sym)
		contact = EmailContact.new(data: Contact.dummy_contact_data)
		contact.save!(validate: false)
		contact.reload

		party = self.namespaced_class(party_sym).new()
		party.contact = contact
		party.contact_strategy = Contact::CONTACT_METHODS[0]
		self.parties << party	# implicit party.save()?
		party
	end
		
	#
	# Create a Tranzaction's Valuables
	#
	def create_valuables(params = nil)
		self.class.valuables.each do |valuable_sym|
			klass = self.namespaced_class(valuable_sym)
			valuable = klass.new 
			valuable.tranzaction = self
			if (params.nil?) then
				valuable.value = klass.value
			else
				valuable.value = params[index][:value]
				stripped_params = params[index].remove(:value)
				valuable.mass_assign_params(stripped_params)
			end
			party = self.model_instance(klass.owner)
			if party.nil? then
				raise "missing model instance '#{klass.owner}'" if party.nil?
			end
			valuable.origin = party
			valuable.disposition = party 
			self.valuables << valuable
			valuable.save!
		end
		return self.valuables 
	end

	#
	# Create a Tranzaction's Expirations
	#
	def create_expirations(params = nil)
		self.class.expirations.each_with_index do |sym, index|
			klass = self.namespaced_class(sym)
			expiration = klass.new 
			expiration.offset = params.nil? ? klass::DEFAULT_OFFSET : params[:offset]
			expiration.offset_units = params.nil? \
				? klass::DEFAULT_OFFSET_UNITS : params[:offset_units]
			expiration.tranzaction = self
			expiration.save!
		end
	end

	#
	# Push a request to provision (create an Artifact)
	#
	# If request is successful, goal will be called back on method
	# provision() when the appropriate Artifact has been created.
	#
	def request_provision(goal)
		return if goal.class.artifact().nil?
		# Note call up to controller layer!
		broadcast_to_channel(Rails.application.routes.url_helpers.new_goal_artifact_path(goal.id))
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

	########################################################################################
	#
	# Server Push Implementation.  The other half of this is the registeration process,
	# which happens in the layout through javascript partials in views/shared.
	#

	# Update the flash message in the Party's current view
	def flash_party(party, msg)
		channel = self.class.path_for_flash_channel(party.contact.user)
		message = { :channel => channel, :data => msg }.to_json
		uri = URI.parse(PUSH_SERVER)
		Net::HTTP.post_form(uri, :message => message)
	end

	# Broadcast to listeners registered for 'channel'.
	def broadcast_to_channel(channel)
		message = { :channel => channel, :data => channel }.to_json
		uri = URI.parse(PUSH_SERVER)
		Net::HTTP.post_form(uri, :message => message)
	end

	def self.path_for_flash_channel(user)
		user_id = user.is_a?(User) ? user.id : user
		channel = ['users', user_id, 'flash']
		channel.join('/')
	end

	########################################################################################
	#
	# class accessors for constants
	#
	def title()
		return self.title if self.methods.include? :title
		self.contract_name
	end

	def self.summary()
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		descriptor_class::SUMMARY
	end

	def self.contract_name
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		descriptor_class::CONTRACT_NAME
	end

	def self.version
		self::VERSION
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

	def self.author_email
		self::AUTHOR_EMAIL
	end

	########################################################################################
	#
	# Setup state_machine for collecting data from Party initiating Tranzaction
	#
	# Contract must define the following constants for the state machine:
	# WIZARD_STEPS, FORWARD_TRANSITIONS, REVERSE_TRANSITIONS, DEPENDENCIES

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

	def configuring_party?
		self.class::PARTY_ROSTER.include? self.wizard_step.camelize.to_sym
	end

	########################################################################################
	#
	# Contract validation.  Call this from spec code.
	#
	# Constants below must be defined in the Contract (subclass of Contract)
	#
	def self.valid_contract?()
		raise "contract_constants_defined?() called on Contract itself!" \
			if self.class == Contract

		# Add validations for newly authored Contracts below
		self.verify_constants()
	end

	#
	# TODO: add more tests...
	#
	def valid_contract?()
		((self.house.kind_of?(Party)) ? true : false) and self.class.valid_contract?
	end

	CONSTANT_LIST = [ \
		'VERSION', 'VALUABLES', 'AUTHOR_EMAIL', 'TAGS', 'EXPIRATIONS',
		'CHILDREN', 'ARTIFACT', 'PARTY_ROSTER', 'WIZARD_STEPS', 'SUMMARY',
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
