class Party < ActiveRecord::Base
	has_one		:role
	has_one		:user
	has_many	:obligation_party
	has_many	:obligations, :through => :obligation_party, :class_name => :Obligation 
	belongs_to	:transaction

	def to_s
		"user = #{user}, role = #{role}, transaction = #{transaction}, obligations = #{obligations}"
	end
end
