require 'active_support'

class Object
	#
	# Get the constant of this name defined in 'self's namespace
	#
	def namespaced_const(name)
		clean = name.to_s.split ':'
		klass = clean[-1]
		path = (self.instance_of? Class) ? self : self.class
		path = path.to_s.split('::').select {|seg| seg != ""}
		path.pop
		path = (path.join('::') + '::' + klass)
		path.constantize
	end

	#
	# Take the name of a constant, truncate its namespace path, and turn
	# it into a symbol.
	#
	def self.const_to_symbol(name)
		(name.to_s.split('::')[-1]).to_sym
	end

	#
	# Determine if a constant of this name is defined in 'self's namespace
	#
	def self.valid_constant?(name)
		begin
			name.to_s.constantize
			return true
		rescue NameError
			namespaced_const name
			return true
		rescue NameError
			false
		end
	end
end
