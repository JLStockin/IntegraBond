class ClauseRole < ActiveRecord::Base
	attr_accessible :role_id

	belongs_to	:clause
	belongs_to	:role

	validates :clause_id,		presence:	true
	validates :role_id,			presence:	true
end
