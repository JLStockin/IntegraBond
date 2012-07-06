class Obligation < ActiveRecord::Base
	attr_accessible	:state, :milestones

	belongs_to	:transaction
	belongs_to	:clause

	has_many	:obligation_party
	has_many	:obligation_valuable

	has_many	:parties, :through => :obligation_party
	has_many	:valuables, :through => :obligation_valuable

	has_many	:evidences

end
