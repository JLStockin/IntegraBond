class GoalsController < ApplicationController
	include UsersHelper
	before_filter :authenticate

	# GET /goals
	# GET /goals.json
	def index
		@goals = Array.new
		parties_for(current_user()).each do |party|
			gls = trans.active_goals(party)
			@goals.push(gls).flatten() unless gls.nil?
		end

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @goals }
		end
	end

	# GET /goals/1
	# GET /goals/1.json
	def show
		@goal = Goal.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @goal }
		end
	end

end
