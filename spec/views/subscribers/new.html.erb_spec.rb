require 'rails_helper'

RSpec.describe "subscribers/new", type: :view do
  before(:each) do
    assign(:subscriber, Subscriber.new(
      :email => "MyString",
      :referrer_id => 1
    ))
  end

  it "renders new subscriber form" do
    render

    assert_select "form[action=?][method=?]", subscribers_path, "post" do

      assert_select "input#subscriber_email[name=?]", "subscriber[email]"

      assert_select "input#subscriber_referrer_id[name=?]", "subscriber[referrer_id]"
    end
  end
end
