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

	#
	# Get the correct partial for the current wizard step
	#
	def partial_for_state(tranzaction)
		tmp = tranzaction.class.to_s.split('::')
		klass_sym = tmp[-1]
		contract_sym = tmp[-2]
		superclass = tranzaction.class.superclass.to_s
		path = "contract_views/#{contract_sym.underscore}/#{klass_sym.underscore}"
		File.join(path, "#{tranzaction.wizard_step}_step")
	end

	#
	# Get the appropriate partial named by partial, for the Contract type
	# obtained from obj, from the immediate parent directory 'directory'
	#
	def partial_for(obj, partial, parent)
		tmp = obj.class.to_s.split('::')
		klass_sym = tmp[-1] # e.g, 'OfferArtifact'
		contract_sym = tmp[-2] # e.g, 'Bet'
		path = nil
		if (parent != '') then
			path = "contract_views/#{contract_sym.underscore}/#{parent}/#{klass_sym.underscore}"
			# e.g, contract_views/bet/artifacts/OfferArtifact
		else
			path = "contract_views/#{contract_sym.underscore}/"
			# e.g, contract_views/bet/
		end
		File.join(path, partial)
	end
end
