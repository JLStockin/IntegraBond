class Party < ActiveRecord::Base
	belongs_to	:transaction
	belongs_to	:user

	def to_s
		"user = #{user}, role = #{role}, transaction = #{transaction}"
	end
end
