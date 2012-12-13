require 'active_support'

class Object
	if false then
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
		self.constants.include? name
	end

	#
	# Get the class for this symbol defined in 'self's namespace
	#
	def namespaced_class(symbol_name)
		clean = symbol_name.to_s.split ':'
		klass = clean[-1]
		path = (self.instance_of? Class) ? self : self.class
		path = path.to_s.split('::').select {|seg| seg != ""}
		path.pop
		path = (path.join('::') + '::' + klass)
		path.constantize
	end
	end
end
