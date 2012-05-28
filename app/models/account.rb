class Account < ActiveRecord::Base
  attr_accessor :available_funds, :total_funds, :user_id

  belongs_to :user

end
