class Valuable < ActiveRecord::Base
	attr_accessible :description, :more_description, :xasset

	belongs_to	:transaction

	monetize	:value_cents

	def to_s
		"#{description} (participates as #{xasset} in #{transaction})"
	end
end
