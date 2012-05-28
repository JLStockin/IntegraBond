class Clause < ActiveRecord::Base
  attr_accessible :relative_t1, :relative_t2, :relative_t3, :ruby_module, :state

  has_many :contracts, through => :contract_clauses
  has_many :xassets, through => :xasset_clauses
  has_many :roles, through => :role_clauses

end
