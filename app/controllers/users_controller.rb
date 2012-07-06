
class UsersController < ApplicationController
	before_filter :authenticate, :except => [:show, :new, :create]
	before_filter :correct_user, :only => [:edit, :update]
	before_filter :admin_user, :only => :destroy

	def index
		@title = "All users"
		@users = User.paginate(:page => params[:page], :per_page => 10) 
	end

	def show
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
			@account.user_id = @user.id		# Needed?

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
		@title = "Edit user"
	end

	def update
		if @user.update_attributes(params[:user])
			flash[:success] = "Profile updated."
			redirect_to @user
		else
			@title = "Edit user"
			render 'edit'
		end
	end

	def destroy
		user = User.find(params[:id])
		name = user.first_name; name += " "; name += user.last_name
		user.destroy
		flash[:success] = "User #{name} destroyed"
		redirect_to(users_path)
	end

	private

		def correct_user
			@user = User.find(params[:id])
			redirect_to(root_path) unless current_user?(@user)
		end

		def admin_user
			if current_user.nil?
				redirect_to(signin_path)
			elsif current_user.admin?
				return true
			else
				redirect_to(root_path)
			end
		end
end
