class Party < ActiveRecord::Base
  attr_accessible :event_id, :role_id, :timestamp, :user_id
end
