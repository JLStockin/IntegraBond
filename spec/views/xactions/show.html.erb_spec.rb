require 'spec_helper'

describe "xactions/show" do
  before(:each) do
    @xaction = assign(:xaction, stub_model(Xaction,
      :party_id => 1,
      :op => "Op",
      :amount_cents => 2
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/Op/)
    rendered.should match(/2/)
  end
end
