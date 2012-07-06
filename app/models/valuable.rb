class Valuable < ActiveRecord::Base
	attr_accessible :description, :more_description

	belongs_to	:xasset
	belongs_to	:grantee, :class_name => :User
	belongs_to	:grantor, :class_name => :User
	#belongs_to	:trustee, :class_name => :User

	has_many	:obligation_valuable
	has_many	:obligations, :through => :obligation_valuable, :class_name => :Obligation

	def to_s
		"xasset = #{xasset},  obligations = #{obligations}"
	end
end
