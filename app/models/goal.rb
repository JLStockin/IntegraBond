#######################################################################################
#
# Several macro methods augment a Goal's statemachine by adding support for fetching params from
# the controller, and adding a mechanism to disable or expire the Goal.  Effectively,
# you can reprogram the state machine on the fly.
#
# When something in the model layer decides a new Goal should be created, it creates
# the Goal, parks it in the :s_unprovisioned state, then tells the Contract 
# about it by calling the Contract's 'request_provision' and/or 'request_expiration'
# methods.  The Contract may turn around and pass the request to the appropriate controller.
# Alternatively, it obtain data from other Artifacts.
#
# The contract calls a separate process to push the request to the client.
#
# The controller determines what the client should render (html, javascript) based on
# model object types, specifically, to which Transaction class (created from Contract)
# they belong.
#
# When the controller's view has collected the params, it calls the goal back on its
# 'provision' method (or 'on_expire').
#
# Macros for augmenting your state machine:
#
#	inject_provisioning -- let the framework fetch Artifact params for you.
#	inject_expiration -- the framework will act on Expirations (DateTime of your choosing)
#	inject_undo -- if you want to be able to undo the actions of your Goal
# 
#
require 'active_support/time'
require 'squeel'

#
# Monkey-patch StateMachine to add 'inject_provisioning' and 'inject_expiration' methods
# so that those two macros are available to the Goal class.  'inject_expiration' # adds
# the 'active?' and 'disable' methods.
#
StateMachine::Machine.class_eval do

	def inject_provisioning()

		# -> start(provision, expiration)
		event :start do
			transition :s_initial => :s_provisioning 
			transition :s_cancelled => :s_provisioning
		end
		before_transition [:s_initial, :s_cancelled] => :s_provisioning do |goal, transition|
			provision = transition.args[0]
			expiration = transition.args[1]
			goal.tranzaction.request_provision(goal) if provision
			goal.tranzaction.request_expiration(goal) if expiration 
			true 
		end

		# -> provision(artifact)
		event :provision do
			transition :s_provisioning => :s_completed
		end

		before_transition :s_provisioning => :s_completed do |goal, transition|
			artifact = transition.args[0]
			if goal.execute(artifact) then
				goal.disable_stepchildren()
				goal.procreate()
				true
			else
				false
			end
		end
	end

	def inject_disable()

		event :disable do
			transition [:s_initial, :s_provisioning] => :s_cancelled
		end
		after_transition [:s_initial, :s_provisioning] => :s_cancelled do |goal, transition|
			Rails.logger.info("Goal #{goal.class.const_to_symbol(goal.class)} disabled.")
			true
		end
	end

	def inject_undo()

		# -> undo
		event :undo do
			transition :s_completed => :s_initial
		end
		before_transition :s_completed => :s_initial do |goal, transition|
			goal.reverse_execution()
			true
		end
	end

	def inject_expiration()

		# -> expire(artifact) 
		event :expire do
			transition :s_provisioning => :s_expired
		end

		before_transition :s_provisioning => :s_expired do |goal, transition|

			artifact = transition.args[0]
			if (!artifact.nil? and artifact.is_a?(goal.namespaced_class(artifact.class))) then
				goal.on_expire(artifact)
				return true
			else
				false
			end
		end

	end

end

class Goal < ActiveRecord::Base
	belongs_to :tranzaction, class_name: Contract, foreign_key: :tranzaction_id
	has_one		:artifact
	has_one		:expiration, as: :owner

	attr_accessible :tranzaction

	validates :tranzaction, presence: true

	CHRON_PERIOD_SECONDS = 5
	
	def self.artifact
		self::ARTIFACT
	end

	def self.expiration
		self::EXPIRATION
	end

	def self.children
		self::CHILDREN
	end

	def self.favorite_child?
		self::FAVORITE_CHILD
	end

	def self.stepchildren
		self::STEPCHILDREN
	end

	def self.available_to
		self::AVAILABLE_TO
	end

	class GoalInitializer
		def self.before_create(record)

			# Workaround for database timestamp issue I can't figure out 
			time = DateTime.now
			record.created_at = time
			record.updated_at = time
			true
		end
	end

	before_create GoalInitializer

	def self.valid_goal?
		constants = [ :ARTIFACT, :CHILDREN, :STEP_CHILDREN,
			:AVAILABLE_TO, :FAVORITE_CHILD, :EXPIRATION \
		]
		valid = true
		constants.each do |constant|
			valid = valid and valid_constant? constant
		end
		valid
	end

	def procreate()
		self.class.children().each do |goal_type|
			goal = self.tranzaction.model_instance(goal_type)
			if goal.nil? then
				klass = self.namespaced_class(goal_type)
				goal = klass.new()
				goal.tranzaction_id = self.tranzaction_id
				goal.save!
			end
			goal.start(true, true)
		end
	end

	def disable_stepchildren()
		self.class.stepchildren().each do |goal_type|
			stepchild = self.tranzaction.model_instance(goal_type)
			raise "stepchild '#{goal_type}' not found" if stepchild.nil?
			stepchild.disable()
		end
	end

	def active?(update=true)
		return (self.can_provision? or self.can_start? or self.can_undo?)
	end

	#
	# Can be called by expire when a Goal times out.  Reverses and disables
	# all the goals.  Creates the EXPIRE_ARTIFACT if it's defined by the Goal.
	#
	def cancel_tranzaction()
		self.tranzaction.reverse_completed_goals(self)
		self.tranzaction.disable_active_goals(self)

		true
	end

	#
	# subclass callbacks
	#

	# Called for provision event
	def execute(artifact)
		raise "subclass must implement execute()"
	end

	# Called for undo event
	def reverse_execution()
		raise "subclass must implement reverse_execution()"
	end

	# Called on a chron event if Goal actually expires
	def on_expire(artifact)
		raise "subclass must implement expire()"
	end

	state_machine :machine_state, :initial => :s_initial do
		inject_provisioning
		inject_undo
		inject_expiration
	end
			
end
