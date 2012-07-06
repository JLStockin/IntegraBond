class ObligationParty < ActiveRecord::Base
	attr_accessible	:party_id
	belongs_to	:obligation
	belongs_to	:party

	def to_s
		"obligation: #{self.obligation} party: #{self.valuable}"
	end
end
