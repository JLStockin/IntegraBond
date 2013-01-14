require 'spec_helper'

describe ActiveRecord::Base do
	it "should have a param_accessor class method" do
		ActiveRecord::Base.should respond_to :param_accessor
	end
end

describe Contracts::Test::TestArtifact do
	before(:each) do
		@trans = Contracts::Test::TestContract.create!
		@artifact = ::Contracts::Test::TestArtifact.new()
		@artifact.tranzaction_id = @trans.id
	end

	it "should create a new instance given valid attributes" do
		@artifact.save!
	end

	it "should respond to immutable" do
		@artifact.should respond_to :immutable
	end

	it "should have accessors" do
		@artifact.should respond_to :a
		@artifact.should respond_to :b
		@artifact.should respond_to :a=
		@artifact.should respond_to :b=
	end

	it "should have working accessors" do
		@artifact.a.should be_nil
		@artifact.b.should be_nil
		@artifact.a = 5
		@artifact.b = 10
		@artifact.a.should be == 5
		@artifact.b.should be == 10 
	end

	it "should have params that persist" do
		@artifact.a.should be_nil
		@artifact.b.should be_nil
		@artifact.a = 5
		@artifact.b = 10
		@artifact.save!
		@artifact.reload
		@artifact.a.should be == 5
		@artifact.b.should be == 10 
	end

	describe "mass assignment" do
		it "should support assignment, retrieval" do
			@artifact.should respond_to :mass_assign_params
			@artifact.should respond_to :mass_fetch_params
		end

		it "should have working methods" do
			@artifact.mass_fetch_params.should be == {}
			@artifact.mass_assign_params( a: 5, b: 10 )
			hash = @artifact.mass_fetch_params
			hash[:a].should be ==  5
			hash[:b].should be == 10 
		end
			
		it "should have accessors that persist data" do
			@artifact.mass_assign_params( a: 5, b: 10 )
			@artifact.save!
			@artifact.reload
			hash = @artifact.mass_fetch_params
			hash[:a].should be ==  5
			hash[:b].should be == 10 
		end

		it "should not allow assignment of illegal params" do
			@artifact.mass_assign_params( a: 5, b: 4, c: 12 )
			@artifact.mass_fetch_params().keys.include?(:c).should_not be_true
		end
	end

	describe "ActiveRecord monkey-patched utilities" do

		describe "namespaced_class()" do
			it "should work on an ActiveRecord::Base instance" do
				@artifact.should respond_to :namespaced_class
				klass = @artifact.namespaced_class(:Friend)
				klass.should_not be_nil
			end

			it "should work on an ActiveRecord::Base-derived class" do
				@artifact.class.should respond_to :namespaced_class
				klass = @artifact.class.namespaced_class(:Friend)
				klass.should_not be_nil
			end
		end

		it "should have a working const_to_symbol() class method" do
			@artifact.class.should respond_to :const_to_symbol
			@artifact.class.const_to_symbol(Contracts::Test::Friend).should be == :Friend
		end

		it "should have a working valid_constant? class method" do
			@artifact.class.should respond_to :valid_constant?
			@artifact.class.valid_constant?(:A_CONSTANT).should be_true	
		end
	end

end
