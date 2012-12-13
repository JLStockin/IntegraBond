module ContactValidatorsModule
	EMAIL_REGEX = /^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/i
	PHONE_REGEX = /^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/
		# replacement text: (\1) \2-\3

	def _validate(record, pattern)
		record.errors[:contact_data] << "(#{record.contact_data}) is not valid" unless
			!record.contact_data.nil? and \
			!record.contact_data.empty? and \
			record.contact_data =~ pattern


	end

end
