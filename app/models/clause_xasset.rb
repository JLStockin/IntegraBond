class ClauseXasset < ActiveRecord::Base
	attr_accessible :xasset_id, :asset_type

	belongs_to		:clause
	belongs_to		:xasset

	validates :clause_id,		presence:	true
	validates :xasset_id,		presence:	true
end
