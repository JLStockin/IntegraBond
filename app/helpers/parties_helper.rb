module PartiesHelper

	# List of tuples with which to populate the find select box
	#
	def find_list()
		tuples = []
		Contact.subclasses.each_pair do |klass, index|
			tuples << [klass.to_s.constantize::CONTACT_TYPE_NAME, index] 
		end
		tuples
	end

	# List of tuples with which to populate the associates select box,
	# based on current_user.  user == current_user is valid.
	#
	def associates_list()
		assocs = Contract.associates_for(current_user()).all.inject([]) do |ret, assoc|
			unless (assoc.id == 2) then
				ret << [assoc.username, assoc.id]
			end
		end
		assocs
	end

end
