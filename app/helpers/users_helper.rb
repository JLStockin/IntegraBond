module UsersHelper

	def gravatar_for(user, options = { :size => 50 })
		gravatar_image_tag(
			user.username.downcase,
			:alt => "#{user.first_name} #{user.last_name}",
			:class => 'gravatar',
			:gravatar => options
		)
	end

	def admin?
		return @admin
	end

	def parties_for(user)
		Party.parties_for(user)
	end
end
