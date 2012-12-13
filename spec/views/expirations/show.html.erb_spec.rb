require 'spec_helper'

describe "expirations/show" do
  before(:each) do
    @expiration = assign(:expiration, stub_model(Expiration))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
