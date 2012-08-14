require 'spec_helper'

describe "xactions/edit" do
  before(:each) do
    @xaction = assign(:xaction, stub_model(Xaction,
      :party_id => 1,
      :op => "MyString",
      :amount_cents => 1
    ))
  end

  it "renders the edit xaction form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => xactions_path(@xaction), :method => "post" do
      assert_select "input#xaction_party_id", :name => "xaction[party_id]"
      assert_select "input#xaction_op", :name => "xaction[op]"
      assert_select "input#xaction_amount_cents", :name => "xaction[amount_cents]"
    end
  end
end
