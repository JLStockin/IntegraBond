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
#	disable() --
# 
#
require 'active_support/time'
require 'squeel'

#
# Monkey-patch StateMachine to add 'inject_provisioning' and 'inject_expiration' methods
# so that those two macros are available to the Goal class.  'inject_expiration' also
# adds the 'active?', and 'disable' methods.
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
			transition :s_cancelled => :s_provisioning
		end
		before_transition [:s_initial, :s_cancelled] => :s_provisioning do |goal, transition|
			this_artifact_type = goal.class.artifact()
			unless this_artifact_type.nil? then
				this_artifact_class = goal.namespaced_class(this_artifact_type)

				goal.contract.class.request_provisioning(
					goal.id, this_artifact_class, this_artifact_class.params \
				)
			end
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
			unless artifact_type.nil?  then
				artifact_class = goal.namespaced_class(artifact_type)
				artifact = artifact_class.new()
				params = transition.args[1]
				artifact.contract_id = goal.contract_id
				artifact.goal_id = goal.id
				artifact.mass_assign_params(params)
				artifact.save!
			end
			true
		end

		after_transition :s_provisioning => :s_completed do |goal, transition|
			if goal.execute() then
				goal.disable_stepchildren()
				goal.procreate()
			end
			true
		end

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

		# -> chron
		event :chron do
			transition :s_provisioning => :s_expired
		end
		before_transition :s_provisioning => :s_expired do |goal, transition|
			return false if goal.expires_at == :never

			if goal.expires_at.to_i <= DateTime.now.in_time_zone.to_i then
				goal.expire()
				true
			else
				false
			end
		end

		Goal.class_eval do

			def procreate()
				self.class.children().each do |goal_type|
					goal = self.contract.model_instance(goal_type)
					if goal.nil? then
						klass = self.namespaced_class(goal_type)
						goal = klass.new()
						goal.contract_id = self.contract_id
						goal.save!
					end
					goal.start()
				end
			end

			def disable_stepchildren()
				self.class.stepchildren().each do |goal_type|
					stepchild = self.contract.model_instance(goal_type)
					raise "stepchild '#{goal_type}' not found" if stepchild.nil?
					stepchild.disable()
				end
			end

			def active?(update=true)
				self.chron if update
				return (self.can_provision? or self.can_start? or self.can_undo?)
			end

			def disable_other(other)
				obj = self.contract.model_instance(other)
				obj.disable
			end

			#
			# Can be called by expire when a Goal times out.  Reverses and disables
			# all the goals.  Creates the EXPIRE_ARTIFACT if it's defined by the Goal.
			#
			def cancel_transaction()
				self.contract.reverse_completed_goals(self)
				self.contract.disable_active_goals(self)

				unless self.class.expire_artifact.nil? then
					artifact = self.class.namespaced_class(self.class.expire_artifact).new()
					artifact.contract_id = self.contract_id
					artifact.save!
				end

				true
			end

			#
			# The first goal doesn't have an artifact, so its expiration is
			# a constant obtained from the offer artifact class.
			# The rest of the expirations have intelligent defaults, but
			# can be modified by provisioning the offer artifact.
			#
			def get_expiration()
				my_type = self.class.const_to_symbol(self.class)
				offer_artifact_type = self.contract.class.artifact
				offer_artifact_class = self.namespaced_class(offer_artifact_type)
				offer_artifact = self.contract.latest_model_instance(offer_artifact_type)

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

	def self.expire_artifact
		self::EXPIRE_ARTIFACT
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

	def self.description
		self::DESCRIPTION
	end

	class GoalInitializer
		def self.before_create(record)

			# Workaround for rails bug
			time = DateTime.now
			record.created_at = time
			record.updated_at = time
			true
		end
	end

	before_create GoalInitializer

	def self.valid_goal?
		constants = [ :ARTIFACT, :EXPIRE_ARTIFACT, :CHILDREN,
			:STEP_CHILDREN, :AVAILABLE_TO, :DESCRIPTION,
			:FAVORITE_CHILD \
		]
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
