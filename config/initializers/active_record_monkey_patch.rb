ActiveRecord::Base.instance_eval do

	#
	# By creating a DB field called _ar_data, we can get ActiveRecord STI
	# to permit free-form subclass data by funneling it into a single field
	# via YAML.  The methods below add this functionality to an ActiveRecord-derived
	# subclass.
	#
	# We also define a mass_assign_params() and a mass_fetch_params().
	#
	# Finally, we create accessor methods that sift through STI associations
	# and return object(s) of the appropriate class.  For example, it will add
	# the method party1() to access the association of type :Party1 through the
	# association :parties
	#
	def param_accessor(*accessors)

		class_eval do

			class << self
				attr_accessor :_param_accessors
			end
			self._param_accessors = accessors 

			serialize :_ar_data, Hash

			def mass_assign_params(params)
				params = self.class._symbolize_and_validate_params(params)
				return nil if params.nil?

				write_attribute(:_ar_data, {}) if self.read_attribute(:_ar_data).nil?
				data = read_attribute(:_ar_data)
				data.merge!(params)
				write_attribute(:_ar_data, data)
			end

			def mass_fetch_params()
				write_attribute(:_ar_data, {}) if self.read_attribute(:_ar_data).nil?
				data = read_attribute(:_ar_data)
				data.is_a?(Hash) ? data : YAML::load(read_attribute(:_ar_data))
			end

		end

		instance_eval do

			def _symbolize_and_validate_params(params)
				fixed_params = {}
				params.each_pair do |param, value|
					param = param.to_sym
					fixed_params[param] = value if self._param_accessors.include? param
				end
				fixed_params
			end
		end

		accessors.each do |accessor|

			define_method(accessor) do
				write_attribute(:_ar_data, {}) if self.read_attribute(:_ar_data).nil?
				data = read_attribute(:_ar_data)
				#data.is_a?(Hash) \
				#	? data[accessor]\
				#	: (YAML::load(read_attribute(:_ar_data)))[accessor]
				data[accessor]
			end

			define_method("#{accessor}=") do |value|
				data = read_attribute(:_ar_data)
				write_attribute(:_ar_data, {}) if data.nil?
				write_attribute(:_ar_data, data.merge(accessor.to_sym => value))
			end
		end

	end

	#
	# Get the class for this symbol defined in 'self's namespace.
	# Not the instance method version, farther below.
	#
	def namespaced_class(symbol_name)
		path = self
		_internal_namespaced_class(path, symbol_name)
	end

	def _internal_namespaced_class(path, symbol_name)
		clean = symbol_name.to_s.split ':'
		klass = clean[-1]
		path = path.to_s.split('::').select {|seg| seg != ""}
		path.pop
		path = (path.join('::') + '::' + klass)
		path.constantize
	end
end

ActiveRecord::Base.class_eval do

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
		self.constants.include? name.to_s.to_sym
	end

	#
	# Get the class for this symbol defined in 'self's namespace
	#
	def namespaced_class(symbol_name)
		path = self.class
		self.class._internal_namespaced_class(path, symbol_name)
	end

	def self.verify_constants()
		bad_constant = ""
		begin	
			self::CONSTANT_LIST.each do |constant_name|
				bad_constant = constant_name
				self.const_get(constant_name)
			end
			return true
		rescue NameError
			raise "#{self.class.to_s}: undefined constant #{bad_constant}"
		end
	end

end
