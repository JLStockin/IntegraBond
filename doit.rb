require 'state_machine'

StateMachine::Machine.class_eval do

	def inject_provisioning(*accessors)
		event :start do
			transition :s_initial => :s_final
		end
	end
end

class A 

	state_machine :machine_state, initial: :s_initial do
		inject_provisioning(:a, :b)
	end
end


a = A.new
a.start
puts "machine_start_name = #{a.machine_state_name}"
