###################################################################################
#
#
#
module IBContracts; end
module IBContracts::Bet; end

module IBContracts::Bet

	class ContractBet < Contract::Base 

		# Stuff specific to this contract 
		VERSION = "0.1"
		CONTRACT_NAME = "Two-Party Wager"
		SUMMARY = "Bet between two parties.  Bet is bond amount."

		AUTHOR_EMAIL = "cschille@gmail.com" 

		VALUABLES = [ \
			{:Party1Bet => "First Party's bet"},
			{:Party2Bet => "Second Party's bet"},
			{:Fees => "Transaction fees to be paid by winner"},
		]

		CHILDREN = [:GoalTenderOffer, :GoalCancelOffer]

		ARTIFACT = :OfferArtifact		# GoalTenderOffer constructs one of these

		DEFAULT_BOND = {:Party1 => Money.parse("$20"), :Party2 => Money.parse("$20")}

		#
		# This is temporary.  It should call a controller to request input. 
		#
		def self.request_provisioning(goal_id, artifact_class, initial_params)
			# TODO: Tell controller
		end

		# Helpers
		def party1
			ret = self.model_instance(:Party1)
			ret
		end

		def party2
			ret = self.model_instance(:Party2)
			ret
		end

		def other_party(party)
			party == :Party1 ? :Party2 : :Party1
		end

		def party1_bet 
			ret = self.model_instance(:Party1Bet)
			ret
		end

		def party2_bet
			ret = self.model_instance(:Party2Bet)
			ret
		end

		def party1_fees
			ret = self.model_instance(:Party1Fees)
			ret
		end

		def party2_fees
			ret = self.model_instance(:Party2Fees)
			ret
		end

	end

end # IBContracts::Bet

require File.dirname(__FILE__) + '/goal_tender_offer'

class P

	# Controller response to a provisioning request
	def self.prov
		puts "Goals: "
		goals = Goal.where(machine_state: "s_provisioning")
		goals.each do |g|
			puts "#{g.inspect}"
		end
		print "Goal ID? > "
		goal_id = gets.chop.to_i

		g = Goal.find(goal_id)
		puts "Select params from params shown to configure as {a: 5, b: 10} etc."
		puts "#{(g.namespaced_const(g.class.artifact))::PARAMS}"
		print "\>  "
		params = gets.chomp
		params = eval params

		all_params = (g.namespaced_const(g.class.artifact))::PARAMS
		all_params.merge!(params)
puts "params for artifact: '#{all_params}'"
		g.provision(g.class.artifact, all_params)
	end

	def to_s
		"-- #{goal_id}) #{Goal.find(goal_id).class}"
	end
end

def cls
	system "cls"
end

def prov
	P.prov
end

@contract = IBContracts::Bet::ContractBet.new
@contract.start
