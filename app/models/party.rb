##############################################################################################
#
# Party -- connects a user and her Account to a role in a Transaction.
#
# One or more Xactions describe how money moves around with respect to her account.
#
##############################################################################################
class Party < ActiveRecord::Base

	attr_accessible :user_id, :contract_id

	belongs_to	:contract, class_name: Contract::Base, foreign_key: :contract_id
	belongs_to	:user

	validates	:contract_id, presence: true
	validates	:user_id, presence: true

	def to_s
		"user = #{user}, role = #{self.class}, contract = #{contract}"
	end

end
