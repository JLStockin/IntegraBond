class ContractClause < ActiveRecord::Base
	attr_accessible :clause_id

	belongs_to :contract
	belongs_to :clause

	validates :clause_id,		presence:	true
	validates :contract_id,		presence:	true

end
