#################################################################################
#
# Base class for ActiveRecord STI derived classes.  Artifact class names are
# important: Goal's statemachine events are named after them.
# When 'ArtifactFoo' is sent as an event to a Goal, the Goal's statemachine will
# not receive the event unless it processes an event called ':artifact_foo'
#
# Address events to Goals via the Transaction, e.g,
#	af = ArtifactFoo.create(...)
#   agoal = GoalImportant.create(...)	=>  GoalImportant contains event :artifact_foo do {...}
#	trans.send_event(af)				=>  af will reach agoal if not expired and processes event
#
class Artifact < ActiveRecord::Base

	belongs_to	:contract, class_name: Contract::Base, foreign_key: :contract_id

	validates	:contract_id, presence: true

	# These params must be specified by the subclass.  They should be a hash containing
	# default values where appropriate.  Forms will know what to do with them.
	# For hashed times, the time indicated is an offset from the 'created_at' timestamp
	# of the keyed Artifact. e.g, the appointment date/time is 24 hours after the
	# creation of the Artifact of class 'Acceptance'.
	# 
	# EX: PARAMS = { :appointment =>	{ :Acceptance => { :hours => 24 } },
	#                :late =>			{ :Acceptance => { :hours => 24, :minutes => 15 } },
	#                :seller_bond =>	"$20" \
	#              }
	#
	# Call param_accessor() to create a serialized hash for your params
	#
	def self.params
		self.class::PARAMS
	end


end
