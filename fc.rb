###################################################################################
#
# FC -- Fake Controller
#
# Drives the system from the command line
#
# rails console
# load "fc.rb"
# fc.create() -or - fc.join(transaction id)
#
class FC

	class << self
		attr_accessor :transaction
	end

	# Controller response to a provisioning request
	def self.go(party_id)

		puts "Available Actions: "
		goals = @transaction.active_goals(party_id == :all ? :all : Party.find(party_id))
		goals.each do |goal|
			puts "#{goal.id} -- #{goal.class.description}"
		end
		
		print "Action? > "
		goal_id = gets.chop.to_i

		if goal_id != 0 then
			g = Goal.find(goal_id)
			unless g.class.artifact.nil? then
				puts "Select params from params shown to configure as {a: 5, b: 10} etc."
				puts "#{(g.namespaced_class(g.class.artifact))::PARAMS}"
				print "\>  "
				params = gets.chomp

				params = eval params if (params != "")

				all_params = ((g.namespaced_class(g.class.artifact))::PARAMS).dup
				all_params.merge!(params) if params != ""
				g.provision(g.class.artifact, all_params)
			else
				g.provision(g.class.artifact, nil)
			end
		end
	end

	def self.create()
		@transaction = IBContracts::Bet::ContractBet.new
		@transaction.start
	end

	def self.set_transaction(id)
		@transaction = Contract::Base.find(id)
	end

end

def cls
	system "cls"
end

def cleanup
	Contract::Base.destroy_all
	Xaction.destroy_all
end

def create()
	FC.create()
end

def join(transaction_id)
	FC.set_transaction(transaction_id)
end
	
def go(party_id=:all)
	FC.go(party_id)
end

ActiveRecord::Base.logger = Rails.logger.clone
ActiveRecord::Base.logger.level = Logger::INFO
Rails.logger = Logger.new(STDOUT)
Rails.logger.level = Logger::INFO

puts "Menu:"
puts "-> cls"
puts "-> cleanup"
puts "-> create"
puts "-> join(transaction_id)"
puts "-> go(party_id=:all)"

