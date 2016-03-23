require 'rails_helper'

RSpec.describe "subscribers/edit", type: :view do
  before(:each) do
    @subscriber = assign(:subscriber, Subscriber.create!(
      :email => "MyString",
      :referrer_id => 1
    ))
  end

  it "renders the edit subscriber form" do
    render

    assert_select "form[action=?][method=?]", subscriber_path(@subscriber), "post" do

      assert_select "input#subscriber_email[name=?]", "subscriber[email]"

      assert_select "input#subscriber_referrer_id[name=?]", "subscriber[referrer_id]"
    end
  end
end
