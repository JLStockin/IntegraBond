class Clause < ActiveRecord::Base
  
	# Utility
	def user_exists(id)
		return User.where(:id => id).nil?() ? false : true
	end
	
	def involve(role)
		@roles << role
	end

	def involved?(role)
		return (roles.find_by_id!(:role_id => role.id, :clause_id => self.id)).nil?() ? true : false
	end
	def valid_role?
		puts ClauseRole.all
		errors.add(:base, "role #{self.name} not found") \
			unless ClauseRole.all.include?(self.id)
	end

	attr_accessible :name, :relative_milestones, :ruby_module

	has_many	:contract_clause
	has_many	:clause_role
	has_many	:clause_xasset
	has_many	:contracts, :through => :contract_clause
	has_many	:roles, :through => :clause_role
	has_many	:xassets, :through => :clause_xasset
	belongs_to	:author, :class_name => :User

	validates	:ruby_module,			presence:	true
	validates	:relative_milestones,	presence:	true
	#validates	:author_id,				presence:	true,
	#	if:			lambda { |id| user_exists(id) }

end
