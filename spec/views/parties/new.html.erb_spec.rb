require 'spec_helper'

describe "parties/new" do
  before(:each) do
    assign(:party, stub_model(Party).as_new_record)
  end

  it "renders new party form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => parties_path, :method => "post" do
    end
  end
end
