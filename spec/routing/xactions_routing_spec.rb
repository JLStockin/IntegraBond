require "spec_helper"

describe XactionsController do
  describe "routing" do

    it "routes to #index" do
      get("/xactions").should route_to("xactions#index")
    end

    it "routes to #new" do
      get("/xactions/new").should route_to("xactions#new")
    end

    it "routes to #show" do
      get("/xactions/1").should route_to("xactions#show", :id => "1")
    end

    it "routes to #edit" do
      get("/xactions/1/edit").should route_to("xactions#edit", :id => "1")
    end

    it "routes to #create" do
      post("/xactions").should route_to("xactions#create")
    end

    it "routes to #update" do
      put("/xactions/1").should route_to("xactions#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/xactions/1").should route_to("xactions#destroy", :id => "1")
    end

  end
end
