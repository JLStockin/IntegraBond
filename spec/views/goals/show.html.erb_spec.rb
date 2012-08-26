require 'spec_helper'

describe "goals/show" do
  before(:each) do
    @goal = assign(:goal, stub_model(Goal,
      :type => "Type",
      :transaction_id => 1,
      :machine_state => 2,
      :state_params => "State Params",
      :description => "Description",
      :more_description => "More Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Type/)
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/State Params/)
    rendered.should match(/Description/)
    rendered.should match(/More Description/)
  end
end
