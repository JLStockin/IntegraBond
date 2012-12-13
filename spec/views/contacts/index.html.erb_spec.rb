require 'spec_helper'

describe "contacts/index" do
  before(:each) do
    assign(:contacts, [
      stub_model(Contact,
        :type => "Type",
        :contact_data => "Contact Data",
        :owner_id => 1
      ),
      stub_model(Contact,
        :type => "Type",
        :contact_data => "Contact Data",
        :owner_id => 1
      )
    ])
  end

  it "renders a list of contacts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Type".to_s, :count => 2
    assert_select "tr>td", :text => "Contact Data".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
