require 'state_machine'

class Foo
	attr_accessor :party_located

	def initialize()
		self.party_located = false
		super
	end

	FORWARD_TRANSITIONS = [
		{
			on: :step,
				s_initial:      :terms,
				terms:          :party2,
				confirm:        :tendered
		},
		{
			on: :step,
			    party2:			:confirm,
				:if				=>	:party_located?
		}
	]
	BEFORE_CALLBACKS = [
		{
			on: :step,
				party2:			:confirm,
				do:				:info
		}
	]

	def party_located?()
		self.party_located
	end

	def info()
		puts "info() called!"
	end

	class_eval do
		StateMachine::Machine.new(self, attribute: :wizard_step)
		self.state_machine.initial_state = :s_initial 

		# Forward steps <----- :next_step, :can_next_step?
		self::FORWARD_TRANSITIONS.each do |transition_defs|
			self.state_machine.transition(transition_defs)
		end

		self::BEFORE_CALLBACKS.each do |callback_defs|
			self.state_machine.before_transition(callback_defs)
		end
	end
			
end

