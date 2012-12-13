require 'spec_helper'

describe "expirations/new" do
  before(:each) do
    assign(:expiration, stub_model(Expiration).as_new_record)
  end

  it "renders new expiration form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => expirations_path, :method => "post" do
    end
  end
end
