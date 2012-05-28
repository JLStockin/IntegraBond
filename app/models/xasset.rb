class Xasset < ActiveRecord::Base
  attr_accessor :clause_id, :destination_role_id, :name, :origination_role_id, :type

  has_many:clauses

end
