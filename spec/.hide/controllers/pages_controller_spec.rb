require 'spec_helper'

describe PagesController do
	render_views

	before(:each) do
		@base_title = SITE_NAME 
	end

	topics = ['about', 'help']

	topics.each do |topic|
		describe "GET #{topic}" do
			it "returns http success" do
				get topic 
				response.should be_success
			end

			it "should have the right title" do
				get topic 
				topic_title = topic
				if (topic_title == "about")
					topic_title = "How it works"
				else
					topic_title = topic_title.camelize :upper
				end
				response.should have_selector("title",
					:content => "#{@base_title} | #{topic_title}")
			end
		end
	end

	describe "GET 'home'" do

		describe "when not signed in" do

			before(:each) do
				get :home
			end

			it "should be successful" do
				response.should be_success
			end


			it "should have the right title" do
				response.should have_selector("title",
					:content => "#{@base_title} | Home")
			end
		end

		describe "when signed in" do

		end
	end
end
