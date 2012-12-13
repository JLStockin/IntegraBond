require 'spec_helper'

describe "expirations/index" do
  before(:each) do
    assign(:expirations, [
      stub_model(Expiration),
      stub_model(Expiration)
    ])
  end

  it "renders a list of expirations" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
