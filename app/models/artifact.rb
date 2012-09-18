#################################################################################
#
#
class ArtifactCreator
	def self.before_create(record)
	end
end

class Artifact < ActiveRecord::Base

	attr_accessible :contract_id

	def self.params
		self::PARAMS
	end

	belongs_to	:contract, class_name: Contract::Base, foreign_key: :contract_id

	validates	:contract_id, presence: true

	#before_create ArtifactCreator

	# These params must be specified by the subclass.  They should be a hash containing
	# default values where appropriate.  Forms will know what to do with them.
	# PARAMS = ...

	def self.inherited(subclass)
		after_inherited do
			subclass.instance_eval do
				param_accessor	*self.params.keys
				#attr_accessible *self.params.keys
			end
		end
	end
end
