require 'active_support'

class Object
	def namespaced_const(name)
		clean = name.to_s.split ':'
		klass = clean[-1]
		path = (self.instance_of? Class) ? self : self.class
		path = path.to_s.split('::').select {|seg| seg != ""}
		path.pop
		path = (path.join('::') + '::' + klass)
		path.constantize
	end

	def const_to_symbol(name)
		(name.to_s.split('::')[-1]).to_sym
	end

	def valid_constant?(name)
		begin
			name.to_s.constantize
			return true
		rescue NameError
			puts "hit first rescue"
			namespaced_const name
			puts "passed second lookup ok"
			return true
		rescue NameError
			puts "failed on second rescue"
			false
		end
	end
end

module A
	module B
		CONST = 5
	end
end

class A::B::C
end

c = A::B::C.new
puts "0) namespaced_const 'CONST' = #{c.class.namespaced_const 'CONST'}"
puts "1) namespaced_const :CONST = #{c.class.namespaced_const :CONST}"
puts "2) namespaced_const :CONST = #{c.namespaced_const :CONST}"
puts "2.5) namespaced_const :C = #{c.namespaced_const(:C).new}"

puts "3) const_to_symbol A::B::CONST = #{c.class.const_to_symbol A::B::CONST}"
puts "4) const_to_symbol :A = #{c.const_to_symbol :A}"
puts "5) const_to_symbol 'CONST' = #{c.const_to_symbol 'CONST'}"
puts "6) const_to_symbol :CONST = #{c.const_to_symbol :CONST}"

