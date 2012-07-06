class ObligationValuable < ActiveRecord::Base
	attr_accessible	:valuable_id

	belongs_to	:obligation
	belongs_to	:valuable

end
