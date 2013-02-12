
class UsersController < ApplicationController
	before_filter :authenticate, :except => [:new, :create]
	before_filter :admin_user, :only => [:index, :destroy]

	def index
		@title = "Your Associates"
		@associates = current_user.admin? \
			? Contract.all
			: Contract.tranzaction_associates(current_user())
		# @associates = @associates.paginate(:page => params[:page], :per_page => 10) 
	end

	def show
		# TODO: make this the public view (add privacy protection) if user != current_user
		@user = User.find(params[:id])
		@title = "#{@user.first_name} #{@user.last_name}"
	end

	def new
		if signed_in?
			redirect_to(root_path)
			return
		else
			@user = User.new
			@title = "Sign up now."
		end
	end

	def create
		if signed_in?
			redirect_to(root_path)
			return
		else
			@user = User.new(params[:user])
			User.transaction do
				@user.username = params[:user][:email]
				@user.save
				@user.create_or_update_contact("EmailContact", params[:user][:email])
				@user.create_or_update_contact("SMSContact", params[:user][:phone])
			end

			unless @user.new_record?
				sign_in @user
				flash[:success] = "Welcome to #{SITE_NAME}."
				redirect_to tranzactions_path and return
			else
				@title = "Sign up"
				@user.password = ""
				render 'new'
			end
		end
	end

	def edit
		@user = current_user()
		@title = "#{@user.first_name} #{@user.last_name}"
	end

	def update
		@user = current_user()
		email = params[:user][:email]
		phone = params[:user][:phone]

		result = true
		result = @user.create_or_update_contact("EmailContact", email) unless email.nil? 
		(result = result and @user.create_or_update_contact("SMSContact", phone)) unless phone.nil? 
		@user.active_contact = params[:user][:active_contact]

		(fail_edit and return) unless result

		if @user.update_attributes(params[:user])
			flash[:success] = "Profile updated."
			redirect_to tranzactions_path and return
		else
			fail_edit
		end
	end

	def fail_edit
		@title = "#{@user.first_name} #{@user.last_name}"
		render 'edit' and return
	end

	def destroy
		user = User.find(params[:id])
		name = user.first_name; name += " "; name += user.last_name
		if (user.id != current_user().id) then
			user.destroy
			flash[:success] = "User #{name} destroyed"
		else
			flash[:error] = "You can't destroy yourself!"
		end
		redirect_to(users_path) and return
	end

end
