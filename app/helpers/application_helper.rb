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
	# Get the correct partial for the current wizard step
	#
	def partial_for_step(tranzaction)
		tmp = tranzaction.class.to_s.split('::')
		klass_sym = tmp[-1]
		contract_sym = tmp[-2]
		superclass = tranzaction.class.superclass.to_s
		path = "contract_views/#{contract_sym.underscore}/#{klass_sym.underscore}"
		File.join(path, "#{tranzaction.wizard_step}_step")
	end

	#
	# Duplicate logic used in ActiveRecord to transform an object into
	# an index into the params hash
	#
	def model_object_to_params_key(model_object)
		model_object.class.to_s.to_lower.split('::').join('_')
	end
end
