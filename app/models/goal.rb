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
#	set_expiration() --
#	active?() --
#	deactivate() --
# 
#
require 'active_support/time'

#
# Monkey-patch StateMachine to add 'inject_provisioning' and 'inject_expiration' methods
# so that those two macros are available to the Goal class.  'inject_expiration' also
# adds the 'set_expiration', 'active?', and 'deactivate' methods.
#
StateMachine::Machine.class_eval do
	def inject_provisioning(initial_state, ready_state)

		event :start do
			transition initial_state => :s_provisioning
		end
		before_transition initial_state => :s_provisioning do |goal, transition|
			artifact_class = goal.contract.namespaced_const(goal.class::ARTIFACT)
			goal.contract.request_provisioning(
				artifact_class, goal.id, artifact_class::PARAMS \
			)
			true
		end

		event :provision do
			transition :s_provisioning => ready_state 
		end
		before_transition :s_provisioning => ready_state do |goal, transition|
			artifact_class = goal.contract.namespaced_const(goal.class::ARTIFACT)
			params = transition.args[0]
			artifact = artifact_class.new(params)
			artifact.contract_id = goal.contract_id
			artifact.save!
		end
	end

	def inject_expiration(recovery_state)
		event :chron do
			expired_callback = lambda \
				do |goal|
					return false if goal.expires_at == :never
					goal.expires_at.to_i < DateTime.now.to_i
				end
			active_callback = lambda \
				do |goal|
					return true if goal.expires_at == :never
					goal.expires_at.to_i >= DateTime.now.to_i
				end
			transition all - :s_expired => :s_expired, :if => expired_callback
			transition :s_expired => recovery_state, :if => active_callback
		end

		Goal.class_eval do

			def active?(); return self.machine_state_name != :s_expired; end

			def activate(date)
				raise "no date given" if date.nil?
				self.expires_at = date 
				self.chron
			end

			def deactivate()
				self.expires_at = DateTime.now().advance(seconds: -1)
				self.chron
			end

			def self.evaluate_expiration(expr)
				ret = self.instance_eval(expr)
				ret
			end

		end
	end
end

class Goal < ActiveRecord::Base
	belongs_to :contract, class_name: Contract::Base, foreign_key: :contract_id
	attr_accessible :contract_id

	validates :contract_id, presence: true

	class GoalInitializer
		def self.before_create(record)
			record.expires_at = record.class::evaluate_expiration(record.class::EXPIRE)
			true
		end
	end

	before_create GoalInitializer

	def self.valid_goal?
			
	end
end
