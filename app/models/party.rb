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

	validates	:contract, presence: true
	validates	:user, presence: true

	def user_identifier
		# Temporary!
		self.user.email
	end

	def to_s
		"user = #{user}, role = #{self.class}, contract = #{contract}"
	end

	def self.role_name
		self::ROLE_NAME
	end

end
