class Class
	def param_accessor(*accessors)
		accessors.each do |accessor|
			define_method(accessor) do
				"called #{accessor} for read"
				instance_eval do
					self.hash[accessor]
				end
			end

			define_method("#{accessor}=") do |value|
				"called #{accessor} for write of #{value}"
				instance_eval do
					self.hash[accessor] = value
				end
			end
		end
	end
end

class Test
	attr_accessor :hash

	def initialize()
		self.hash = {}
	end
	param_accessor :param1, :param2
end

test = Test.new
test.param1 = 5
test.param2 = 5
test.param1
test.param2
				
