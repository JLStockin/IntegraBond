#######################################################################################
#
# Infrastructure for supporting Contracts.  Contract classes must include this file as
# a mixin, which takes care of registering it.  Instances of the Contract class are
# Transactions (an arbitrarily complicated interaction between two or more parties).
#
# NB: Xactions are simple financial transactions that work at a lower level.
#
module TransactionInstance

	def read_transaction_param(param)
		@transaction_params[param]
	end

	def write_transaction_param(param, value)
		@transaction_params[param] = value
	end

	# To keep a new contract author from doing anything sketchy, this should only
	# be called once, when the parties are created.
	#
	def bond_amount(role)
		self.contract_params[:bond_amount].nil? \
			? Money.parse(DEFAULT_BOND) : self.contract_params[:bond_amount]
	end

	def fees_for(role)
		FEES[self.type]
	end

	def party(role)
		parties.each do |party|
			return party if party.role == role
		end
		raise "role '#{role}' not found!"
	end

	#
	# Get access to privates when testing
	#
	if Rails.env != "test" then
		private
	end
		def set_defaults
			return if self.class == TransactionInstance

			self.milestones ||= self.class::INITIAL_MILESTONES
			self.machine_state ||= self.class::INITIAL_MACHINE_STATE
			self.type ||= self.class.to_s

			self.contract_params ||= {}
			self.contract_params[:fault] ||= self.class::INITIAL_FAULT
			self.contract_params[:limit_counter_offer] ||= false 
		end

		#
		# TODO -- implement
		# 
		def message(user, evidence)
			true
		end

		#
		# Look for evidence in this transaction matching the passed hash.  Example:
		#
		# :subject => role.party.user
		# :object => role.other_party().party.user
		# :verb => ack_arrive
		# :location => transaction_params[:location]
		# :between => {@milestones[:meet], \
		#   @milestones[:meet] + @milestones[:late])
		#
		def evidence?(hash)
			return false if evidences.empty? or evidences.nil?

			candidates = evidences.dup()
			hash.each_pair do |key, value|
				candidates.each do |candidate|
					if candidate.hash[:verb].nil? or candidate.hash[:verb] != hash[:verb] then
						candidates.delete(candidate)
					end
				end
				return false if candidates.empty?()
			end
			true		
		end

		def TransactionInstance.valid_constant?(name)
			name = name.split("::")
			return false if name.length < 2
			name = name[-1]
			Module.const_get(Transaction::CONTRACT_NAMESPACE).const_get(name)
			return true
		rescue NameError
			false
		end
end
