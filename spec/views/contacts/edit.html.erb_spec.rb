require 'spec_helper'

describe "contacts/edit" do
  before(:each) do
    @contact = assign(:contact, stub_model(Contact,
      :type => "",
      :contact_data => "MyString",
      :owner_id => 1
    ))
  end

  it "renders the edit contact form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => contacts_path(@contact), :method => "post" do
      assert_select "input#contact_type", :name => "contact[type]"
      assert_select "input#contact_contact_data", :name => "contact[contact_data]"
      assert_select "input#contact_owner_id", :name => "contact[owner_id]"
    end
  end
end
