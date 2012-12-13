require 'spec_helper'

describe "parties/index" do
  before(:each) do
    assign(:parties, [
      stub_model(Party),
      stub_model(Party)
    ])
  end

  it "renders a list of parties" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
