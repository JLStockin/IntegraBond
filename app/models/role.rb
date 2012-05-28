class Role < ActiveRecord::Base
  attr_accessible :clause_id, :name

  belongs_to :clause

end
