##############################################################################
#
# **Extend** this Module to have the PARAMS hash turned into its own hash with
# accessors.  The data hash is serialized into _ar_data_ using YAML.
#
module Provisionable

	def params
		(self.valid_constant?(:PARAMS) and !self::PARAMS.nil?) ? self::PARAMS : nil
	end

	def inherited(subclass)
		super
		after_inherited do
			subclass.instance_eval do
				param_accessor	*self.params.keys unless self.params.nil?
			end
		end
	end

	#
	# This allows us to muck with a subclass during inherited, but *after*
	# we've interpreted the class contents
	#
	def after_inherited(child = nil, &blk)
		line_class = nil
		set_trace_func(\
			lambda do |event, file, line, id, binding, classname|
				if line_class.nil?
					# save the line of the inherited class entry
					if event == 'class' then
						line_class = line
					end
				else
					# check the end of inherited class
					if event == 'end' then
						# if so, turn off the trace and call the block
						set_trace_func nil
						blk.call child
					end
				end
			end
		)
	end

	def provisionable?
		params().nil? ? false : true
	end

	def valid_artifact?(base_klass)
		raise "you must derive a class from #{base_klass}" if self == base_klass

		constants = [ 
			IMMUTABLE \
		]
		valid = true
		constants.each do |constant|
			valid = valid and valid_constant? constant
		end
		valid
	end
end
