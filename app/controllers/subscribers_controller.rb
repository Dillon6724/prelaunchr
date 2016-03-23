class SubscribersController < InheritedResources::Base

  # will need to uncomment this method before launching in production
  # before_filter :handle_ip, only: :create

  def new
    @subscriber = Subscriber.new
  end

  def create
    ref_code = cookies[:h_ref].downcase if ref_code
    email = params[:subscriber][:email]
    @subscriber = Subscriber.new(email: email)
    @subscriber.referrer = User.find_by_referral_code(ref_code) if ref_code

    if @subscriber.save
      cookies[:h_subscriber] = { value: "true"}
      redirect_to 'www.verilymag.com' and return # REDIRECT WHERE, EXACTLY?
    else
      logger.info("Error saving user with email, #{email}")
      redirect_to root_path, alert: 'Something went wrong!'
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
