module ApplicationHelper

	# Return a title on a per-page basis.
	def title
		base_title = SITE_NAME
		if @title.nil?
			base_title
		else
			"#{base_title} | #{@title}"
		end
	end


	def logo_tag()
		foo = image_tag(	"#{SITE_NAME}_logo.png",
					:alt => "#{SITE_NAME}", :class => "round")
		#raise("**********************  logo() returns #{foo}")
		image_tag(	"#{SITE_NAME}_logo.png",
					:alt => "#{SITE_NAME}", :class => "round")
	end

	def startup_video
		return "./video/Splash.flv"
	end

	def splash_screen_image
		return "./images/logo.png"
	end

end
