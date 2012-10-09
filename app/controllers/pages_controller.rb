class PagesController < ApplicationController

  def home
    @title = "Home" if signed_in?
	end
  end

  def about 
    @title = "How it works"
  end

  def help 
    @title = "Help"
  end

end
