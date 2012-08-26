##############################################################################################
#
# Party -- connects a user and her Account to a role in a Transaction.
#
# One or more Xactions describe how money moves around with respect to her account.
#
##############################################################################################
class Party < ActiveRecord::Base

	belongs_to	:transaction
	belongs_to	:user

	validates :user, presence: true
	validates :transaction, presence: true

	def to_s
		"user = #{user}, role = #{self.class}, transaction = #{transaction}"
	end

end
