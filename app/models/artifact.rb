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
	belongs_to	:origin, class_name: Party
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

	CONSTANT_LIST = [
		'IMMUTABLE'
	]

	def fire_goal()
		goal = self.goal
		unless goal.nil?
			if ( self.is_a?(ExpiringArtifact) ) then
				goal.expire!(self)
			elsif ( self.is_a?(ProvisionableArtifact) )
				goal.provision(self)
			end
		end
	end

	def status_description_for
		raise "status_description_for must be implemented in the subclass"
	end

	def action_description_for
		raise "action_description_for must be implemented in the subclass"
	end

	def lookup_description_template(table_sym, key) 
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		table_class = "#{descriptor_class.to_s}::#{table_sym.to_s}".constantize

		prefix = self.created_at.nil?\
			? nil : self.created_at.to_formatted_s(:long) + " "
		desc = nil 
		if table_sym == :ARTIFACT_STATUS_MAP and prefix then
			desc = prefix + table_class[self.to_symbol()][key]
		else
			desc = table_class[self.to_symbol][key]
		end
		raise "invalid lookup table #{table_sym}" if desc.nil?
		desc
	end

	def substitute_user(s, current_user, other_party, pattern)
		return s if s.scan(pattern).empty?

		your_party = self.tranzaction.party_for(current_user)
		identity = (your_party.id == other_party.id) ? :you : :other
		s = s.sub(
			pattern,
			self.namespaced_class(:ModelDescriptor)::ID_MAPPINGS[identity]
		)
		if identity == :other then
			s = s.sub(
				'%FIRSTNAME%',
				other_party.user.first_name
			).sub(
				'%LASTNAME%',
				other_party.user.last_name
			)
		end
		return s
	end

	def originator?(user)
		self.tranzaction.party_for(user).id == self.origin.id
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
