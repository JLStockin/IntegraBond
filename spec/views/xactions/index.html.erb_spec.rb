require 'spec_helper'

describe "xactions/index" do
  before(:each) do
    assign(:xactions, [
      stub_model(Xaction,
        :party_id => 1,
        :op => "Op",
        :amount_cents => 2
      ),
      stub_model(Xaction,
        :party_id => 1,
        :op => "Op",
        :amount_cents => 2
      )
    ])
  end

  it "renders a list of xactions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Op".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
  end
end
