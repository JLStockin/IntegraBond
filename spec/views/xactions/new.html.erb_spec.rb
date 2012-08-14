require 'spec_helper'

describe "xactions/new" do
  before(:each) do
    assign(:xaction, stub_model(Xaction,
      :party_id => 1,
      :op => "MyString",
      :amount_cents => 1
    ).as_new_record)
  end

  it "renders new xaction form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => xactions_path, :method => "post" do
      assert_select "input#xaction_party_id", :name => "xaction[party_id]"
      assert_select "input#xaction_op", :name => "xaction[op]"
      assert_select "input#xaction_amount_cents", :name => "xaction[amount_cents]"
    end
  end
end
