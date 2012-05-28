class ContractClauses < ActiveRecord::Base

  validates :clause_id,		presence:	true
  validates :contract_id,	presence:	true

  belongs_to :contract
  belongs_to :clause

end
