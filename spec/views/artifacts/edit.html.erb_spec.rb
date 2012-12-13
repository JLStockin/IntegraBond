require 'spec_helper'

describe "artifacts/edit" do
  before(:each) do
    @artifact = assign(:artifact, stub_model(Artifact))
  end

  it "renders the edit artifact form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => artifacts_path(@artifact), :method => "post" do
    end
  end
end
