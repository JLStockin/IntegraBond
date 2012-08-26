class Object 
	# The hidden singleton lurks behind everyone
	def metaclass; class << self; self; end; end

	def meta_eval &blk; metaclass.instance_eval &blk; end
		  
	# Adds methods to a metaclass
	def meta_def name, &blk
		meta_eval { define_method name, &blk }
	end
						 
	# Defines an instance method within a class
	def class_def name, &blk
		class_eval { define_method name, &blk }
	end

end

class Fancy 
	def self.param_accessor( symbol )
		class_def symbol do
			param_read(symbol)
		end
		class_def "{symbol.to_s}=".to_sym do |val|
			param_write(symbol, val)
		end
	end
end

class A
	param_accessor :carrot

	def param_read(name)
		puts "param_read(#{name}) called!"
	end

	def param_write(name, value)
		puts "param_write(#{name}) called!"
	end
end

#a = A.new
#a.carrot = "carrot"
#puts "a.carrot is #{a.carrot}"


class MailTruck
	def self.company(name)
		class_def :company do
			@name
		end
		class_def :company= do |val|
			@name = val
		end
	end
end

class HappyTruck < MailTruck
	company "Happy Truck"
end

h = HappyTruck.new
h.company
