ActiveRecord::Base.instance_eval do

	def param_accessor(*accessors)

		class_eval do

			serialize :_ar_data, Hash

			def mass_assign_params(*params)
				self._ar_data ||= {}
				self._ar_data.merge!(*params)
			end

			def mass_fetch_params()
				self._ar_data ||= {}
				self._ar_data.class == Hash \
					? self._ar_data \
					: YAML::load(self._ar_data)
			end
		end

		accessors.each do |accessor|

			define_method(accessor) do
				self._ar_data ||= {}
				self._ar_data.class == Hash \
					? self._ar_data[accessor] \
					: (YAML::load(self._ar_data))[accessor]
			end

			define_method("#{accessor}=") do |value|
				self._ar_data ||= {}
				self._ar_data[accessor] = value
			end
		end
	end
end

