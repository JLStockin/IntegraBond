IntegraBond::Application.routes.draw do

	# TODO: add contracts#new.  This is called when source for a new Contract type has been
	# copied to the server, and the new Contract should be loaded and registered in the
	# running system
	#

	# Tranzaction creation
	# GET /contracts => contracts#index
	# GET /contracts/5 => contracts#show
	# GET /contracts/5/tranzactions/new => contracts#new 
	# POST /contracts/5/tranzactions => contracts#create
	resources :contracts, :only => [:index, :show] do
		resource :tranzactions, :only => [:new]
	end

	resources :parties, only: [:edit, :update]

	# Tranzaction monitoring, history
	# GET /tranzactions => tranzactions#index
	# GET /tranzactions/14 => tranzactions#show
	# GET /tranzactions/14/edit => tranzactions#edit
	# POST /tranzactions/14/ => tranzactions#update
	# GET /tranzactions/14/artifacts => artifacts#index
	# GET /tranzactions/14/artifacts/21 => artifacts#show
	resources :tranzactions, :only => [:index, :show, :edit, :update] do
		resources :artifacts, :only => [:index, :show]
		resources :parties, :only => [] do
			resources :invitations, :only => [:new, :create]
		end

	end

	# Tranzaction control
	resources :goals, :only => [:index, :show] do
		resources :artifacts, :only => [:new, :create]
	end

	resources :expirations, :only => [] do
		collection { post 'sweep', :action => 'expirations#sweep' }
	end

	# Users
	resources :users, :except => [:destroy] do
		resource :account, :only => [:show]
		resources :contacts
	end

	# Sessions
	resources :sessions, :only		=> [:new, :create, :destroy]

  	match '/signup', :to => 'users#new'
  	match '/signin', :to => 'sessions#new'
  	match '/signout', :to => 'sessions#destroy'
  	match '/about', :to => 'pages#about'
  	match '/help', :to => 'pages#help'

	root :to => 'pages#home'
end
