class SubscribersController < InheritedResources::Base

  # will need to uncomment this method before launching in production
  before_filter :handle_ip, only: :create

  def new
    # this anti-cheating code seems to be giving inconsistent results. Disabling for now.

    # if cookies[:h_subscriber] = "true"
      # redirect_to 'https://verilymag.com' and return # to VERILYMAG.com
    # else
      @subscriber = Subscriber.new
    # end
  end

  def create
    ref_code = cookies[:h_ref].downcase if cookies[:h_ref]
    email = params[:subscriber][:email]
    @subscriber = Subscriber.new(email: email)
    @subscriber.referrer = User.find_by_referral_code(ref_code) if ref_code

    if @subscriber.save
      begin
        gb = Gibbon::Request.new
        gb.lists(ENV["NEWSLETTER_LIST_ID"]).members.create(body: {
          email_address: email,
          status: "subscribed",
          merge_fields: {
            MMERGE2: "VIP"
          }
        })
        cookies[:h_subscriber] = { value: "true"}
        cookies.delete :h_ref
        redirect_to subscribers_url and return # REDIRECT WHERE, EXACTLY?
      rescue Gibbon::MailChimpError => e
        puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
        flash[:notice] = "Looks like you've already signed up to our email list. Would you like to become a VIP? Click here to find out more."
        redirect_to new_subscriber_url, alert: 'Something went wrong!'

      end
    else
      logger.info("Error saving user with email, #{email}")
      flash[:notice] = "Looks like you've already signed up to our email list. Would you like to become a VIP? Click here to find out more."
      redirect_to new_subscriber_url, alert: 'Something went wrong!'
    end
  end

  private

    def subscriber_params
      params.require(:subscriber).permit(:email, :referrer_id)
    end

    def handle_ip
      # Prevent someone from gaming the site by referring themselves.
      # Presumably, users are doing this from the same device so block
      # their ip after their ip appears three times in the database.
      address = request.env['HTTP_X_FORWARDED_FOR']
      return if address.nil?

      current_ip = IpAddress.find_by_address(address)
      if current_ip.nil?
        current_ip = IpAddress.create(address: address, count: 1)
      elsif current_ip.count > 2
        logger.info('IP address has already appeared three times in our records.
                   Redirecting user back to landing page.')
        return redirect_to root_path
      else
        current_ip.count += 1
        current_ip.save
      end
    end
end
