class Contract < ActiveRecord::Base
	attr_accessible :name, :ruby_module, :summary, :tags

	has_many :clauses, :through => :contract_clauses

end
