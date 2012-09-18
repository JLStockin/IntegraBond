#######################################################################################
#
# Two methods augment a Goal's statemachine by adding support for fetching params from
# the controller, and adding a mechanism to disable or expire the Goal.
#
# When something in the model layer decides a new Goal should be created, it creates
# the Goal, parks it in the :s_unprovisioned state, then tells the Contract 
# about it by calling the Contract's 'provision' method.  The Contract may turn 
# around and pass the request to the appropriate controller, or it may make inquieries
# of other Artifacts.
#
#	controller.provision(class_for_context, callback, param_list) 
#
# The controller can use 'class_for_context' to select appropriate form(s) to send the user.
# It's recommended that you use an Artifact class.
#
# When the controller has collected the params, it calls the goal back via ContractManager.
#
#
# The parameter hash is passed with the state machine event.  The object can then extract
# the param values and use them to create an Artifact.  If successful, its state changes
# to the state specified in the call to inject_provisioning().
#
# Macros for augmenting your state machine:
#
#	add_provisioning -- let the framework fetch Artifact params for you.
#
#	add_expiration -- the framework will deactivate your Goal at time 'expires_at'
#		(if you have called 'add_expiration'), adding the following methods too:
#	active?() --
#	deactivate() --
# 
#
require 'active_support/time'
require 'squeel'

#
# Monkey-patch StateMachine to add 'inject_provisioning' and 'inject_expiration' methods
# so that those two macros are available to the Goal class.  'inject_expiration' also
# adds the 'active?', and 'deactivate' methods.
#
# The Artifact_class (or list of them) passed up to the controller in request_provisioning
# isn't interpreted by the Goal.  It can, for example, be a module or list instead, and contain 
# several Artifact classes.  The controller can choose which of these classes to return 
# in the call to Goal::provision().
#
StateMachine::Machine.class_eval do
	def inject_provisioning()

		# -> start
		event :start do
			transition :s_initial => :s_provisioning
		end
		before_transition :s_initial => :s_provisioning do |goal, transition|
			this_artifact_type = goal.class.artifact()
			this_artifact_class = goal.namespaced_const(this_artifact_type)

			goal.contract.class.request_provisioning(
				goal.id, this_artifact_class, this_artifact_class::PARAMS \
			)
			goal.expires_at = goal.get_expiration()
			true
		end

		after_transition :s_initial => :s_provisioning do |goal, transition|
			true
		end

		# -> provision 
		event :provision do
			transition :s_provisioning => :s_completed
		end

		before_transition :s_provisioning => :s_completed do |goal, transition|
			artifact_type = transition.args[0]
			artifact_class = goal.namespaced_const(artifact_type)
			artifact = artifact_class.new()
			params = transition.args[1]
			artifact.contract_id = goal.contract_id
			artifact.mass_assign_params(params)
			artifact.save!
			true
		end

		after_transition :s_provisioning => :s_completed do |goal, transition|
			goal.deactivate_stepchildren()
			goal.execute()
			goal.procreate()
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

		# -> chron
		event :chron do
			transition :s_provisioning => :s_expired
		end
		before_transition :s_provisioning => :s_expired do |goal, transition|
			return false if goal.expires_at == :never

			if goal.expires_at.to_i <= DateTime.now.to_i then
				goal.expire()
				true 
			else
				false
			end
		end

		Goal.class_eval do

			def procreate()
				self.class.children().each do |goal_type|
					klass = self.namespaced_const(goal_type)
					goal = klass.new()
					goal.contract_id = self.contract_id
					goal.save!
					goal.start()
				end
			end

			def deactivate()
				if self.can_provision? or self.can_start? then
					self.expires_at = DateTime.now().advance(seconds: -1)
					self.save!
					self.chron
				end
			end

			def deactivate_stepchildren()
				self.class.stepchildren().each do |goal_type|
					stepchild = self.contract.model_instance(goal_type)
					raise "stepchild '#{goal_type}' not found" if stepchild.nil?
					stepchild.deactivate()
				end
			end

			def active?(update=true)
				self.chron if update
				return (self.can_provision? or self.can_start? or self.can_undo?)
			end

			def deactivate_other(other)
				obj = self.contract.model_instance(other)
				obj.deactivate
			end

			#
			# First goal doesn't have an artifact, so its expiration is
			# a constant obtained from the offer artifact class.
			# The rest of the expirations have intelligent defaults, but
			# can be modified by provisioning the offer artifact.
			#
			def get_expiration()
				my_type = self.class.const_to_symbol(self.class)
				offer_artifact_type = self.contract.class.artifact
				offer_artifact_class = self.namespaced_const(offer_artifact_type)
				offer_artifact = self.contract.model_instance(offer_artifact_type)

				expirations = ( offer_artifact.nil? ) \
					?  offer_artifact_class::PARAMS[:expirations]\
					:  offer_artifact.expirations

				evaluate_expiration(expirations)
			end

			def evaluate_expiration(expirations)
				mySym = self.class.const_to_symbol(self.class)
				entry = expirations[mySym]
				return entry if entry.kind_of? Symbol	# e.g, :never

				relative = entry[0]
				expr = entry[1]
				return (eval expr).call if relative.nil?		# e.g, [nil, "lambda..."]

				other_goal = self.contract.model_instance(relative)
				(eval expr).call(other_goal.created_at)	# e.g, [:GoalAcceptOffer, "lambda..."]
			end

			#
			# subclass callbacks
			#

			# Called for provision event
			def execute()
				raise "subclass must implement execute()"
			end
		
			# Called for undo event
			def reverse_execution()
				raise "subclass must implement reverse_execution()"
			end
		
			# Called on a chron event if Goal actually expires
			def expire()
				raise "subclass must implement expire()"
			end
		end
	end

end

class Goal < ActiveRecord::Base
	belongs_to :contract, class_name: Contract::Base, foreign_key: :contract_id
	attr_accessible :contract_id

	validates :contract_id, presence: true

	CHRON_PERIOD_SECONDS = 5
	
	def self.artifact
		self::ARTIFACT
	end

	def self.children
		self::CHILDREN
	end

	def self.stepchildren
		self::STEPCHILDREN
	end

	class GoalInitializer
		def self.before_create(record)
			true
		end
	end

	before_create GoalInitializer

	def self.valid_goal?
		constants = [ :ARTIFACT, :CHILDREN, :STEP_CHILDREN ]
		valid = true
		constants.each do |constant|
			valid = valid and valid_constant? constant
		end
		valid
	end

	#
	# Called by a controller to send data back to a Goal.
	#
	def self.provision(goal_id, artifact_class, params)
		goal = Goal.find(goal_id)
		goal.send(:provision, artifact_class, params)
	end

	#
	# Logic to take care of moving transactions forward in time, so that they can expire.
	#
	def self.check_goals_for_expiration
		recently = DateTime.now.advance(seconds: -self::CHRON_PERIOD_SECONDS * 2)

		Goal.where{ (expires_at <= recently) & (machine_state == ":s_provisioning") }.each do |goal|
			goal.transaction do
				goal.chron
			end
		end
	end

	state_machine :machine_state, :initial => :s_initial do
		inject_provisioning
		inject_undo
		inject_expiration
	end
			
end
