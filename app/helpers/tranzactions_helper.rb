module TranzactionsHelper
	#
	# For a given user, for each of the user's tranzactions,
	# create a hash of { <tranzaction> => {<party_class> => <party>} }.
	# Return an array containing [<all party classes>, <hash from above>]
	#
	def format_tranzaction_data_for(user)
		data = {} 

		return nil if Contract.tranzactions_for(user).nil?

		Contract.tranzactions_for(user).each do |trans|
			party_list = {}
			unless trans.nil? then
				trans.parties.each do |party|
					party_list[party.class] = party
				end
				data[trans] = party_list
			end
		end

		klasses = data.inject(Set.new) do |set, trans_record|
			set + trans_record[1].keys
		end
		[klasses, data]
	end

	def contract_klass(contract_id)
		::ContractManager.contracts(contract_id)	
	end

	def status_for(tranzaction)
		model_descriptor(tranzaction).status_for(tranzaction)
	end

	def associates_list(tranzaction)
		assocs = Contract.associates_for(current_user).collect do |assoc| 
			unless	(assoc.id == current_user().id or assoc.id == 2) then
				elem = [assoc.username, assoc.id]
			end
		end
		assocs.compact!
	end

end
