class Obligation < ActiveRecord::Base
  attr_accessible :clause_id, :t1, :t2, :transaction_id
end
