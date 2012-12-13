require 'spec_helper'

describe "artifacts/new" do
  before(:each) do
    assign(:artifact, stub_model(Artifact).as_new_record)
  end

  it "renders new artifact form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => artifacts_path, :method => "post" do
    end
  end
end
