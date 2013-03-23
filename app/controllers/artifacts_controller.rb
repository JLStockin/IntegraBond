class ArtifactsController < ApplicationController
	include ApplicationHelper
	before_filter :authenticate

	# GET /transactions/1/artifacts
	# GET /transactions/1/artifacts.json
	def index
		@artifacts = Tranzaction.find(params[:tranzaction_id]).artifacts.all

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @artifacts }
		end
	end

	# GET /artifacts/1
	# GET /artifacts/1.json
	def show
		@artifact = Artifact.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @artifact }
		end
	end

	# GET /goals/:goal_id/artifacts/new
	def new 
		@goal = Goal.find(params[:goal_id])
		@tranzaction = @goal.tranzaction
		party = @tranzaction.party_for(current_user)
		@artifact = @tranzaction.build_artifact_for(@goal, party)
		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @artifact }
		end
	end

	# POST /goals/:goal_id/artifacts
	def create
		(redirect_to tranzactions_path and return) if params[:previous_button]

		goal = Goal.find(params[:goal_id])

		tranzaction = goal.tranzaction
		party = tranzaction.party_for(current_user)
		artifact = tranzaction.build_artifact_for(goal, party)

		new_params = params[model_object_to_params_key(artifact)]
		artifact.mass_assign_params(new_params)

		# Fix race condition with other Parties
		goal.with_lock do
			if goal.active? then
				artifact.save!
				artifact.fire_goal()
			else
				artifact = tranzaction.latest_artifact
			end
		end

		notice = artifact.status_description_for(current_user())  
		redirect_to tranzactions_path, :notice => notice 
	end

end
