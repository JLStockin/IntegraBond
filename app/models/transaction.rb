class Transaction < ActiveRecord::Base
  attr_accessible :contract_id, :creation_time, :prior_transaction_id, :status
end
