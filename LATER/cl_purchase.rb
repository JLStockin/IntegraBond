###################################################################################
#
# CR Purchase contract and supporting objects 
#
#require "#{Rails.root.join('app', 'model', 'transaction_mixin').to_s}"

module IBContracts::CL

	class CLPurchase < TransactionBase

		include TransactionMixin

		# Stuff specific to this contract 
		VERSION = "0.1"
		CONTRACT_NAME = "Craigslist Purchase Contract"
		SUMMARY = "Local, peer-to-peer sales contract.  No dealers, no shipping, cash " \
			+ "or certified check only for payment.  Meet in person.  Bond appointment.  " \
			+ "If one party is late, a dealer, or requires goods to be shipped, party " \
			+ "forfeits bond.  One reschedule permitted (if within allowable time); " \
			+ "second reschedule forfeits deposit.  Aggrevied party may waive right to " \
			+ "collect deposit for evidence of good faith effort by other party."

		AUTHOR_EMAIL = "cschille@gmail.com" 
		PARTIES = [:PartyBuyer, :PartySeller]
		VALUABLES = [:ValuableBuyerBond, :ValuableSellerBond, :ValuableFees,
			:ValuableSellerGoods]
		GOALS = [:GoalAccept]
		ARTIFACTS = [:ArtifactListing]

		DEFAULT_BOND = {PartyBuyer: Money.parse("$20"), PartySeller: Money.parse("$20")}


		#########################################################################
		#
		#                       Goal Helpers 
		#
		#########################################################################

		def get_location()
			result = read_transaction_param(:appointment_location)
			raise "missing location" if result.nil? 
			result
		end

		def set_location(location)
			write_transaction_param(:appointment_location, location)
		end

		def get_appointment
			result = read_transaction_param(:have_appointment)
			raise "missing appointment" if result.nil? 
			result
		end

		def set_appointment(value)
			write_transaction_param(:have_appointment, value)
		end

		def get_subject_party
			result = read_transaction_param(:subject_role)
			raise "no subject role" if result.nil? 
			result
		end	

		def set_subject_party(party)
			write_transaction_param(:subject_role, role)
		end

		def get_object_party
			result = read_transaction_param(:object_role)
			raise "no object role" if result.nil? 
			result
		end	

		def set_object_party(party)
			write_transaction_param(:object_role, role)
		end

		def other_party(party)
			party == PartyBuyer ? PartySeller : PartyBuyer 
		end
			
		def originate(party)
			raise "Invalid party name '#{party}'" if Transaction.party(party).nil?
			@party_of_origin = party 
			return
		end

	end

end # IBContracts
