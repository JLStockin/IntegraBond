class Xasset < ActiveRecord::Base
    attr_accessible :destination_role_id, :origination_role_id, :name, :asset_type
	
    has_many	:clause_xassets
    has_many	:clauses,			:through => :clause_xassets

	def to_s
		"name = #{self.name}, type = #{self.asset_type}"
	end

end
