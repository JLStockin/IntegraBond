require 'spec_helper'

describe "parties/edit" do
  before(:each) do
    @party = assign(:party, stub_model(Party))
  end

  it "renders the edit party form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => parties_path(@party), :method => "post" do
    end
  end
end
