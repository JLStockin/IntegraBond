class Transaction < ActiveRecord::Base
  attr_accessible :status

  belongs_to :contract
  belongs_to :party_of_origin, :class_name => :User

  has_one :prior_transaction, :class_name => :Transaction
  has_many	:obligations
end
