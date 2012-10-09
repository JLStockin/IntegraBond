#################################################################################
#
#
class ArtifactCreator
	def self.before_create(record)
	end
end

class Artifact < ActiveRecord::Base
	include Comparable

	class << self
		attr_accessor :_inherited
		alias :_inherited :inherited
	end

	attr_accessible :contract_id

	def self.params
		(self.valid_constant?(:PARAMS) and !self::PARAMS.nil?) ? self::PARAMS : nil
	end

	belongs_to	:contract, class_name: Contract::Base, foreign_key: :contract_id
	belongs_to	:goal

	validates	:contract_id, presence: true
	validates	:goal_id, presence: true

	#before_create ArtifactCreator

	def <=>(other)
		return 1 if other.created_at < self.created_at
		return -1 if other.created_at > self.created_at
		return 0 if other.created_at == self.created_at
	end

	# These params must be specified by the subclass.  They should be a hash containing
	# default values where appropriate.  Forms will know what to do with them.
	# PARAMS = ...

	def self.inherited(subclass)
		_inherited(subclass)

		after_inherited do
			subclass.instance_eval do
				param_accessor	*self.params.keys unless self.params.nil?
			end
		end
	end
end
