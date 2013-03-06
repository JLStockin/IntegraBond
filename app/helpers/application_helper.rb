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
		image_tag(	"#{SITE_NAME}_logo.png",
					:alt => "#{SITE_NAME}", :class => "round")
	end

	def startup_video
		return "./video/Splash.flv"
	end

	def splash_screen_image
		return "./images/logo.png"
	end

	#
	# Given a model object from a specific Contract namespace, find the 
	# Helper for the corresponding views
	#
	def model_descriptor(model_object)
		model_object.namespaced_class("ModelDescriptor".to_sym)
	end

	#
	# Duplicate logic used in ActiveRecord to transform an object into
	# an index into the params hash
	#
	def model_object_to_params_key(model_object)
		model_object.class.to_s.underscore.split('/').join('_')
	end
end
