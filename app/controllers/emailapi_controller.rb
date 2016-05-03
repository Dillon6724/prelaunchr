class EmailapiController < ApplicationController
def index
end

def subscribe
    @list_id = ENV["MAILCHIMP_LIST_ID"]
    gb = Gibbon::API.new

    gibbon.lists(list_id).members.create(body: {
      email_address: params[:email],
      status: "subscribed",
      merge_fields: {
        FNAME: params[:first_name],
        LNAME: params[:last_name]
      }
    })


    # gb.lists.subscribe({
    #   :id => @list_id,
    #   :email => {:email => params[:email][:address]}
    #   })
end

end
