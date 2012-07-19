class Valuable < ActiveRecord::Base
	attr_accessible :description, :more_description, :xasset

	belongs_to	:transaction

	def to_s
		"#{description} (participates as #{xasset} in #{transaction})"
	end
end
