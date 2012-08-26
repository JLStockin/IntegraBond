ActiveRecord::Base.instance_eval do
	def param_accessor(*accessors)
		class_eval do
			serialize :_data, Hash
		end

		accessors.each do |accessor|

			define_method(accessor) do
				instance_eval do
					self._data ||= {}
					self._data[accessor]
				end
			end

			define_method("#{accessor}=") do |value|
				instance_eval do
					self._data ||= {}
					self._data[accessor] = value
				end
			end
		end
	end
end

class Apple < ActiveRecord::Base
	param_accessor :a, :b
	serialize :_data, Hash
end
