##############################################################################
#
# **Extend** this Module to have the PARAMS hash turned into its own hash with
# accessors
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

	def provisionable
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
