# This adds an 'after_inherited' method to Class
class Class
	def after_inherited(child = nil, &blk)
		line_class = nil
		set_trace_func(\
			lambda do |event, file, line, id, binding, classname|
				if line_class.nil?
					# save the line of the inherited class entry
					if event == 'class' then
						line_class = line
					end
				else
					# check the end of inherited class
					if event == 'end' then
						# if so, turn off the trace and call the block
						set_trace_func nil
						blk.call child
					end
				end
			end
		)
	end
end

