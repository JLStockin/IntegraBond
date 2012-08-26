class Module
	def attr_accessor( *symbols )
		symbols.each { | symbol | do
			module_eval( "def #{symbol}() @#{symbol}; end" )
			module_eval( "def #{symbol}=(val) @#{symbol} = val; end" )
		end
	end
end

class Foobar 
	attr_accessor :foo
	private
		attr_accessor :bar
end

fb = Foobar.new
fb.foo = "hello"
fb.bar = "world"
puts fb.foo  # >> hello
puts fb.bar  # >> world
