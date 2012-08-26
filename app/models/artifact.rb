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

	# TODO: 
	attr_accessible :transaction_id, :sender_id, :receiver_id

	belongs_to :transaction
	belongs_to :sender, class_name: Party
	belongs_to :receiver, class_name: Party

	def to_event()
		self.class.to_s.underscore.to_sym
	end
end
