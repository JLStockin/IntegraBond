class Evidence < ActiveRecord::Base
  attr_accessible :description, :event_id, :party_id, :source, :type
end
