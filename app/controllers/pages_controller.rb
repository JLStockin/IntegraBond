class PagesController < ApplicationController

  def home
    @title = "Welcome"
	if signed_in? then
		redirect_to tranzactions_path 
		return
	end
  end

  def about 
    @title = "How it works"
  end

  def help 
    @title = "Help"
  end

end
