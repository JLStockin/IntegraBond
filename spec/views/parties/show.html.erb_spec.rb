require 'spec_helper'

describe "parties/show" do
  before(:each) do
    @party = assign(:party, stub_model(Party))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
