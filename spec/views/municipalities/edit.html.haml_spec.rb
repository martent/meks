require 'rails_helper'

RSpec.describe "municipalities/edit", type: :view do
  before(:each) do
    @municipality = assign(:municipality, Municipality.create!(
      :name => "MyString"
    ))
  end

  it "renders the edit municipality form" do
    render

    assert_select "form[action=?][method=?]", municipality_path(@municipality), "post" do

      assert_select "input#municipality_name[name=?]", "municipality[name]"
    end
  end
end