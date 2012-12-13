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
		goal = Goals.find(:goal_id)
		tranzaction = goal.tranzaction
		@artifact = tranzaction.build_artifact_for(goal) 
		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @artifact }
		end
	end

	# POST /goals/:goal_id/artifacts
	def create

		goal = Goal.find(params[:goal_id])
		tranzaction = goal.tranzaction
		artifact = tranzaction.build_artifact_for(goal) 
		param_key = model_object_to_params_key(artifact)
		artifact.mass_assign_params(params[param_key])
		artifact.save!

		redirect_to goals_path, :notice => "Offer Created"
	end

	def register_for_artifacts
end
