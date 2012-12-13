require 'state_machine'

class Foo
	attr_accessor :ambiguous, :found

	def initialize()
		self.found = false
		self.ambiguous = false
		super
	end

	def ambiguous?
		self.ambiguous
	end
	def found?
		self.found
	end

	state_machine :machine_state, :initial => :s_initial do
		event :next_step do
			transition :s_initial => :s_step1
			transition :s_step1 => :s_step2
			transition :s_step2 => :s_step3, :if => lambda {|foo| foo.found? and !foo.ambiguous?}
			transition :s_step2 => :s_step2a, :if => lambda {|foo| !foo.found?}
			transition :s_step2 => :s_step2b, :if => lambda {|foo| foo.ambiguous?}
			transition :s_step2a => :s_step2b, :if => lambda {|foo| foo.ambiguous?}

			transition :s_step2a => :s_step3, :if => lambda {|foo| foo.found? and !foo.ambiguous?}
			transition :s_step2b => :s_step3, :if => lambda {|foo| foo.found? and !foo.ambiguous?}
		end
	end

end
