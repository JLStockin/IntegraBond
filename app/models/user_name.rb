#
# Seems like there's no need to ever construct one of these.  It's just handy
# to so we can call Contact::lookup.  (The validation is just so that
# we can correct the user's typing mistakes.)
#
class UserName < Contact
	USERNAME_RANGE = (8..40)
	validates :contact_data, 	:presence => true,
								:length => { :in => USERNAME_RANGE }
end
