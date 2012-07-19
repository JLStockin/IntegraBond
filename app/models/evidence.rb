class Evidence < ActiveRecord::Base
	attr_accessible :description, :source, :evidence_type

	belongs_to :transaction
end
