require 'spec_helper'

describe "artifacts/index" do
  before(:each) do
    assign(:artifacts, [
      stub_model(Artifact),
      stub_model(Artifact)
    ])
  end

  it "renders a list of artifacts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
