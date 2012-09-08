

# TODO: create macro that creates the contract namespace
module IBContracts
module Test
end
module Bad
end
end

class IBContracts::Test::TestContract < Contract::Base

	VERSION = "0.1"
	CONTRACT_NAME = "Test Contract"
	SUMMARY = "This is a test"
	AUTHOR_EMAIL = "cschille@gmail.com" 

	FIRST_GOAL = :TestGoal

	DEFAULT_BOND = {:Party1 => Money.parse("$20"), :Party2 => Money.parse("$20")}

	TAGS = %W/test default/

	# In real life, this calls a controller or looks at other Artifacts.

	def request_provisioning(artifact_klass, goal_id, initial_params)
		hash = {}
		initial_params.each_key do |param|
			hash[param] = "yes" unless param == :value or param == :expire
		end
		hash[:value] = Money.parse("$100")
		hash[:expire] = initial_params[:expire] 
		ATest.stash_return_values(goal_id, hash)
	end
end

class IBContracts::Test::TestGoal < Goal

	EXPIRE = "DateTime.now.advance( seconds: 2 )"

	ARTIFACT = :TestArtifact

	state_machine :machine_state, initial: :s_initial do
		inject_provisioning(:s_initial, :s_ready)

		event :advance do
			transition :s_ready => :s_my_objects_created
			transition :s_my_objects_created => :s_state2
		end

		before_transition :s_ready => :s_my_objects_created do |goal, transition|

			user1 = User.find(3)
			party1 = goal.contract.class.namespaced_const(:Party1).new
			party1.user_id = user1.id
			party1.contract_id = goal.contract_id
			party1.save!

			user2 = User.find(4)
			party2 = goal.contract.class.namespaced_const(:Party2).new
			party2.user_id = user2.id
			party2.contract_id = goal.contract_id
			party2.save!

			valuable1 = IBContracts::Test::Valuable1.new( \
				contract_id: goal.contract_id,
				value: ATest.the_hash[:price],
				origin_id: party1.id, disposition_id: party1.id \
			)
			valuable1.contract_id = goal.contract_id
			valuable1.save!

			valuable2 = IBContracts::Test::Valuable2.new( \
				contract_id: goal.contract_id,
				value: ATest.the_hash[:price],
				origin_id: party2.id, disposition_id: party2.id \
			)
			valuable2.contract_id = goal.contract_id
			valuable2.save!

			true
		end

		inject_expiration()
	end

end

class IBContracts::Test::TestArtifact < Artifact 

	attr_accessible :a, :b, :price, :value, :expire
	param_accessor :a, :b, :price, :value, :expire

	PARAMS = { a: :no, b: :no, price: Money.parse("$25") }
	
end

class IBContracts::Test::Valuable1 < Valuable
	attr_accessible :value
end

class IBContracts::Test::Valuable2 < Valuable
end

class IBContracts::Test::Party1 < Party
end

class IBContracts::Test::Party2 < Party
end

def cleanup
	Contract::Base.delete 0..100
	Party.delete 0..100
	Goal.delete 0..100
	Artifact.delete 0..100
	Valuable.delete 0..100
end

def cls
	system "cls"
end

class ATest
	class << self
		attr_accessor :goal_id, :the_hash, :trans
	end
	def self.stash_return_values(goal_id, hash)
		self.goal_id = goal_id
		self.the_hash = hash
	end
	def self.start
		trans = IBContracts::Test::TestContract.new
		trans.save!
		trans.start
		ContractManager.provision(self.goal_id, self.the_hash)
		Goal.find(self.goal_id).advance
	end
end
