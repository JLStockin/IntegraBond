#################################################################################
#
#

class ArtifactCallbackHook
	def self.after_commit(record)
		if (record.is_a?(ExpiringArtifact)) then
			record.goal.expire(record)
		elsif ( record.is_a?(ProvisionableArtifact) and !record.goal.nil? )
			record.goal.provision(record)
		end
	end
end

class Artifact < ActiveRecord::Base

	include Comparable

	belongs_to	:tranzaction, class_name: Contract, foreign_key: :tranzaction_id
	belongs_to	:goal
	validates	:tranzaction, presence: true

	after_commit ArtifactCallbackHook

	def <=>(other)
		return 1 if other.created_at < self.created_at
		return -1 if other.created_at > self.created_at
		return 0 if other.created_at == self.created_at
	end

	def immutable
		self::IMMUTABLE
	end

end

class ProvisionableArtifact < Artifact 
	extend Provisionable

	# Params can be specified by the subclass.  They should be a hash containing
	# default values where appropriate.  Forms will know what to do with them.
	# PARAMS = {...}
end

class ExpiringArtifact < Artifact 

end
