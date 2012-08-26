require 'active_support/time'

class Goal < ActiveRecord::Base

	#
	# set_expiration( date, hash=nil )
	# hash can be days: days, hours: hours, minutes: minutes, seconds: seconds
	#
	def set_expiration(date, hash=nil)
		# TODO: implement properly.  See Transaction.rb.
		raise "no date given" if date.nil?
		self.expires_at = hash.nil? ? date : date.advance(hash)
	end

	def active?(); return self.machine_state_name != :s_expired; end

	def deactivate(); self.expires_at = DateTime.now().advance(seconds: -1); self.chron; end

	def send_event(artifact)
		evt = artifact.to_event
		self.send(evt, artifact)
	end

end
