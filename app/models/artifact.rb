#################################################################################
#
#

class ArtifactCallbackHook
	def self.after_initialize(record)
		if record.class.provisionable? then
			record.write_attribute(:_ar_data, {}) if record.read_attribute(:_ar_data).nil?
			record.class.params.each_pair do |param, value|
				record._ar_data[param] = value unless record._ar_data.has_key? param
			end
		end
	end
end

class Artifact < ActiveRecord::Base

	include Comparable

	belongs_to	:tranzaction, class_name: Contract, foreign_key: :tranzaction_id
	belongs_to	:goal
	validates	:tranzaction, presence: true unless Rails.env.test?

	after_initialize ArtifactCallbackHook

	def <=>(other)
		return 1 if other.created_at < self.created_at
		return -1 if other.created_at > self.created_at
		return 0 if other.created_at == self.created_at
	end

	def self.immutable?
		self::IMMUTABLE
	end

	def creation_message()
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		descriptor_class::ARTIFACT_DESCRIPTIONS[ActiveRecord::Base.const_to_symbol(self.class)]
	end

	CONSTANT_LIST = [
		'IMMUTABLE'
	]

	def fire_goal()
		goal = self.goal
		unless goal.nil?
			if ( self.is_a?(ExpiringArtifact) ) then
				goal.expire!(self)
			elsif ( self.is_a?(ProvisionableArtifact) )
				goal.provision!(self)
			end
		end
	end
end

class ProvisionableArtifact < Artifact 
	extend Provisionable

	# Params can be specified by the subclass.  They should be a hash containing
	# default values where appropriate.  Forms will know what to do with them.
	# PARAMS = {...}
end

class ExpiringArtifact < Artifact 
	def self.provisionable?()
		false
	end
end
