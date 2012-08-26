require 'spec_helper'

describe "goals/index" do
  before(:each) do
    assign(:goals, [
      stub_model(Goal,
        :type => "Type",
        :transaction_id => 1,
        :machine_state => 2,
        :state_params => "State Params",
        :description => "Description",
        :more_description => "More Description"
      ),
      stub_model(Goal,
        :type => "Type",
        :transaction_id => 1,
        :machine_state => 2,
        :state_params => "State Params",
        :description => "Description",
        :more_description => "More Description"
      )
    ])
  end

  it "renders a list of goals" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Type".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "State Params".to_s, :count => 2
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    assert_select "tr>td", :text => "More Description".to_s, :count => 2
  end
end
