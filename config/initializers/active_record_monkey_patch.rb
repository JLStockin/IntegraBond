ActiveRecord::Base.instance_eval do

	def param_accessor(*accessors)

		class_eval do

			serialize :_ar_data

			def mass_assign_params(*params)
				self._ar_data ||= {}
				self._ar_data.merge!(*params)
			end

			def mass_fetch_params()
				self._ar_data ||= {}
				self._ar_data	
			end
		end

		accessors.each do |accessor|

			define_method(accessor) do
				instance_eval do
					self._ar_data ||= {}
					self._ar_data[accessor]
				end
			end

			define_method("#{accessor}=") do |value|
				instance_eval do
					self._ar_data ||= {}
					self._ar_data[accessor] = value
				end
			end
		end
	end
end

