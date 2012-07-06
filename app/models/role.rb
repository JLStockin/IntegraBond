class Role < ActiveRecord::Base
	attr_accessible :name

	has_many	:clause_role
	has_many	:clauses, :through => :clause_role

	validates	:name,				presence:	true
end
