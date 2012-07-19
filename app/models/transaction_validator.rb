#
# Validations for Transaction.rb, an abstract base for contracts used in all Transactions
#

class TransactionValidator < ActiveModel::Validator
	def validate(record)
		record.errors[:role_of_origin] << "is not a valid role in this contract" \
			unless record.roles.include? role_of_origin

		if ENV["RAILS_ENV"] == "test" then
			record.errors[:author_email] << "doesn't look like a valid email address" \
				unless !(record.author_email =~ User::EMAIL_REGEX).nil?
		else
			# TODO: put proper email address validation here
		end
	end
end

