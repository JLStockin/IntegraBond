class AccountValidator < ActiveModel::Validator
	def validate(record)
		if (record.get_funds(:available) > record.get_funds(:total)) then
			record.errors[:total_funds] << "Avaliable funds #{record.get_funds(:available)} " +
				"exceed total funds (#{record.get_funds(:total)})"
		end
	end
end

class Account < ActiveRecord::Base
  
	belongs_to :user
	attr_accessible :name 
	validates_with	AccountValidator

	VIEWABLE = [:available, :total]


	# dest: should be one of :available, :total
	def exec_xaction(xaction_type, funds, dest = nil, src = nil)

		if !(VIEWABLE.member? xaction_type) then
			raise("type #{xaction_type} not (yet?) supported for exec_xaction.")
		end

		var = "@#{xaction_type.to_s}_funds"
		statement = "#{var}.nil? "
		statement += "? (#{var} = funds) : (#{var} += funds)"
		binding = self.send(:binding)
		eval(statement, binding)
	end

	def get_funds(which)
		if !(VIEWABLE.member? which) then
			raise("get_funds(): type #{which} not (yet?) supported.")
		end

		var = "@#{which.to_s}_funds"
		statement = "#{var}.nil? "
		statement += "? (#{var} = 0) : #{var}"
		binding = self.send(:binding)
		eval(statement, binding)
	end


	def to_s
		"available funds: #{get_funds(:available)}, total funds = #{get_funds(:total)}"
	end

end
