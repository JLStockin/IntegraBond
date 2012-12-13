#require 'contract'

class ContractsController < ApplicationController
	include TranzactionsHelper

	before_filter :authenticate

	# GET /contracts
	# GET /contracts.json
	def index
		@contracts = ContractManager.contracts

		#redirect_to(new_contract_tranzactions_path(0)) unless @contracts.count > 1 and return

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @contracts }
		end
	end

	# GET /contracts/1
	# GET /contracts/1.json
	def show
		@contract = ContractManager.contracts[:id] 

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @contract }
		end
	end

end
