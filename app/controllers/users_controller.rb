
class UsersController < ApplicationController
	before_filter :authenticate, :except => [:new, :create]
	before_filter :admin_user, :only => :destroy

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
			@account = @user.build_account() # Need to extract the account params

			if @user.save
				sign_in @user
				flash[:success] = "Welcome to #{SITE_NAME}."
				redirect_to @user
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
		if @user.update_attributes(params[:user])
			flash[:success] = "Profile updated."
			redirect_to @user
		else
			@title = "#{@user.first_name} #{@user.last_name}"
			render 'edit'
		end
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
		redirect_to(users_path)
	end

end
