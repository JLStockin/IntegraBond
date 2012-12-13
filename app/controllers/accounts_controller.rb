class AccountsController < ApplicationController
	include AccountsHelper

	before_filter :authenticate

	# GET /users/1/account
	# GET /users/1/account/.json
	def show
		
		@account = current_user().account
		@xactions = Xaction.find(\
			:all,
			:order => "created_at DESC",
			:conditions => \
				["primary_id = (?) or beneficiary_id = (?)",
				current_user().account.id, current_user().account.id\
			]\
		)

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @account }
		end
	end

end
