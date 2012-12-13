require 'spec_helper'

describe "artifacts/show" do
  before(:each) do
    @artifact = assign(:artifact, stub_model(Artifact))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
