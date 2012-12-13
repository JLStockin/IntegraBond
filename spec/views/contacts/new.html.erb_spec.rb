require 'spec_helper'

describe "contacts/new" do
  before(:each) do
    assign(:contact, stub_model(Contact,
      :type => "",
      :contact_data => "MyString",
      :owner_id => 1
    ).as_new_record)
  end

  it "renders new contact form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => contacts_path, :method => "post" do
      assert_select "input#contact_type", :name => "contact[type]"
      assert_select "input#contact_contact_data", :name => "contact[contact_data]"
      assert_select "input#contact_owner_id", :name => "contact[owner_id]"
    end
  end
end
