class Contract < ActiveRecord::Base
	attr_accessible :name, :ruby_module, :summary, :tags

	has_many	:contract_clause
	has_many	:clauses,	:through => :contract_clause,
							:foreign_key => :clause_id
	belongs_to	:author, :class_name => :User
	validates :name, :ruby_module, :summary, :tags, :presence => true

	has_many :transactions

end
