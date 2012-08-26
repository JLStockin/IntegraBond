require 'spec_helper'

describe "goals/new" do
  before(:each) do
    assign(:goal, stub_model(Goal,
      :type => "",
      :transaction_id => 1,
      :machine_state => 1,
      :state_params => "MyString",
      :description => "MyString",
      :more_description => "MyString"
    ).as_new_record)
  end

  it "renders new goal form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => goals_path, :method => "post" do
      assert_select "input#goal_type", :name => "goal[type]"
      assert_select "input#goal_transaction_id", :name => "goal[transaction_id]"
      assert_select "input#goal_machine_state", :name => "goal[machine_state]"
      assert_select "input#goal_state_params", :name => "goal[state_params]"
      assert_select "input#goal_description", :name => "goal[description]"
      assert_select "input#goal_more_description", :name => "goal[more_description]"
    end
  end
end
