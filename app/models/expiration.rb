####################################################################################
#
# Expirations configure the behavior of a Goal by allowing it to respond to the passage
# of time.  Expirations create an Artifact and set the Goal's state to :s_expired.
# An Expiration is created and configured when the tranzaction is.  Therefore,
# it must be bound to the Goal when the Goal is created; hence, the polymorphic
# 'owner' field: this allows us to transfer ownership from the Tranzaction to the
# Goal.
#
class ExpirationCallbackHook
	def self.before_create(record)
		record.offset		= record.class::DEFAULT_OFFSET
		record.offset_units = record.class::DEFAULT_OFFSET_UNITS
	end
end

class Expiration < ActiveRecord::Base
	belongs_to :owner, polymorphic: true
	validates :owner, presence: true

	attr_accessible :offset, :offset_units, :type
	attr_accessor :offset_units_index

	class << self 
		attr_accessor :last_sweep
	end
	last_sweep = 0

	before_create ExpirationCallbackHook

	def bind(goal)
		self.owner = goal
		model_instance = self.tranzaction.model_instance(self.class.basis_type)
		self.value =
			self.owner.namespaced_class(self.class.basis_type).constantize.find(
				model_instance.id
			).created_at.advance(
				self.offset_units.to_sym => self.offset
			)
		self.save!
	end

	def self.sweep()
		now = DateTime.now()
		expirations = Expiration.expiring(self.last_sweep).can_expire
		self.last_sweep = now 

		expirations.each do |expiration|
			goal = expiration.owner()	# Owner could be a Tranzaction
			if goal.is_a? Goal then
				tranzaction = goal.tranzaction
				goal.transaction do
					if goal.can_expire? then
						artifact = tranzaction.build_artifact_for(self)
						artifact.save!
					end
				end
			end
		end
	end

    scope :can_expire, joins{goals.inner}.where{
		(machine_state == "s_provisioning") | (machine_state == "s_initial")
	}

	scope :expiring, lambda { |last_sweep| \
		where{value != nil & value <= DateTime.now & value > last_sweep}
	}

	def self.basis_type
		self::BASIS_TYPE
	end

	#
	# These belong on some sort of decorator rather than this class
	#
	def basis_description()
		if (value.nil?) then
			descriptor_class = self.namespaced_class(:ModelDescriptor)
			goal_desc = descriptor_class::BASIS_TYPE_DESCRIPTIONS[self.class.basis_type]
		else
			self.value		
		end
	end

	def description()
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		descriptor_class::EXPIRATION_LABELS[ActiveRecord::Base.const_to_symbol(self.class)]
	end

	def self.time_units_list()
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		descriptor_class::TIME_UNITS.to_a
	end

	def offset_units_index()
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		descriptor_class::TIME_UNITS[self.offset_units.to_sym]
	end

	def update_attributes(params)
		self.offset = params[:offset].to_i
		descriptor_class = self.namespaced_class(:ModelDescriptor)
		idx = params[:offset_units_index].to_i
		sym_name = descriptor_class::TIME_UNITS.key(idx)
		self.offset_units = sym_name.to_sym
		index = idx.to_s 
		params.delete(:offset_units_index)
		super(params)
		params[:offset_units_index] = index
	end

	def to_s()
		if self.value.nil? then
			"#{self.offset} #{self.offset_units} #{self.basis_description}"
		else
			self.value.to_s
		end
	end

end
