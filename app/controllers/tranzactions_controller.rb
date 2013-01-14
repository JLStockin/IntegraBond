
class TranzactionsController < ApplicationController
	include TranzactionsHelper
	include ApplicationHelper

	before_filter :authenticate
	before_filter :admin_user, :only => :destroy

	CONTACT_METHODS = [
		'Find ',
		'Past associate ', 
		'Allow anyone to accept (and generate an invitation link)'
	]

	# GET /tranzactions
	# GET /tranzactions.json
	def index

		data = format_tranzaction_data_for(current_user)
		@party_classes = data.nil? ? nil : data[0]
		@tranzactions = data.nil? ? nil : data[1]

		respond_to do |format|
			format.html
			format.json { render json: @tranzactions }
		end
	end

	# GET /tranzactions/1
	# GET /tranzactions/1.json
	def show
		@tranzaction = Contract.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @tranzaction }
		end
	end

	# TODO: add Expirations 
	# Get /contracts/:id/tranzactions/new
	def new
		idx = (params[:contract_id]).to_i
		@tranz = Contract.create_tranzaction(::ContractManager.contracts[idx], current_user())
		redirect_to(edit_tranzaction_path(@tranz))
	end

	# Get /tranzactions/:id/edit
	def edit 
		@tranzaction = Contract.find(params[:id].to_i) 
		raise "tranzaction '#{@tranzaction}' not found" if @tranzaction.nil?
	end

	# Post /tranzactions/:id/
	def update 
		@tranzaction = Contract.find(params[:id].to_s) 
		@tranzaction.update_attributes(params)

		if params[:previous_button] and @tranzaction.can_previous_step? then
			@tranzaction.previous_step()
		elsif params[:cancel_button] then
			@tranzaction.destroy()
			redirect_to tranzactions_path and return
		elsif @tranzaction.can_next_step?() then
			@tranzaction.next_step()
		else
			raise "no progress possible"
		end

		if @tranzaction.final_step?() then
			@tranzaction.start()
			redirect_to tranzactions_path and return
		elsif @tranzaction.configuring_party?() then
			@party = @tranzaction.instance_eval(@tranzaction.wizard_step)
			redirect_to(edit_party_path(@party)) and return
		else
			redirect_to(edit_tranzaction_path(@tranzaction)) and return
		end
	end

	# DELETE /tranzactions/1
	# DELETE /tranzactions/1.json
	def destroy
		@tranz = Contract.find(params[:id])
		@tranz.destroy

		respond_to do |format|
			format.html { redirect_to tranzactions_url }
			format.json { head :no_content }
		end
	end

end
