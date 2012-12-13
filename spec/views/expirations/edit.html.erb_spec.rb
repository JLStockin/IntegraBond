require 'spec_helper'

describe "expirations/edit" do
  before(:each) do
    @expiration = assign(:expiration, stub_model(Expiration))
  end

  it "renders the edit expiration form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => expirations_path(@expiration), :method => "post" do
    end
  end
end
