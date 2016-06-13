class UsersController < ApplicationController
  before_filter :skip_first_page, only: :new

  # will need to uncomment this method before launching in production
  before_filter :handle_ip, only: :create

  def new
    @bodyId = 'home'
    @is_mobile = mobile_device?

    if params[:REF]
      cookies[:h_ref] = { value: params[:REF]}
      redirect_to new_subscriber_url and return
    elsif cookies[:h_ref]
      redirect_to new_subscriber_url and return
    end

    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create

    ref_code = cookies[:h_ref].downcase if cookies[:h_ref]
    email = params[:user][:email]
    first_name = params[:user][:first_name]
    last_name = params[:user][:last_name]
    print params
    @user = User.new(email: email)
    cookies[:h_email] = { value: @user.email }
    @user.referrer = User.find_by_referral_code(ref_code) if ref_code


    if @user.save
      cookies[:h_email] = { value: @user.email }
      redirect_to edit_user_url(@user.id)
    else
      logger.info("Error saving user with email, #{email}")
      redirect_to root_path, alert: 'Something went wrong!'
    end
  end

  def launch_list
    email = params[:launch_email]
    begin
      gb = Gibbon::Request.new
      gb.lists(ENV["LAUNCH_LIST_ID"]).members.create(
        body: {
          email_address: email,
          status: "subscribed",
           merge_fields: {
             FNAME: "Friend"
           }
      })
    flash[:notice] = "Thanks for signing up! We'll send you an email soon with more instructions!"
    redirect_to root_path

    rescue Gibbon::MailChimpError => e
      flash[:notice] = "Oops! Something went wrong. It could be that you forgot to enter some information, or that you already have an account associated with that email address. Please email vips@verilymag.com if you continue to experience issues."
      puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
      redirect_to root_path
    end

  end

  def refer

    @bodyId = 'refer'
    @is_mobile = mobile_device?
    @user = User.find_by_email(cookies[:h_email] || params[:user][:email])

    respond_to do |format|
      if @user.nil?
        flash[:notice] = "We don't recognize that email, please sign up!"
        format.html { redirect_to root_path, alert: 'Something went wrong!' }
      else
        cookies[:h_email] = { value: @user.email }
        format.html # refer.html.erb
      end
    end
  end

  def show
    if params[:id]
      @user = User.find(params[:id])
    else
      @user = User.find_by_email(cookies[:h_email])
    end
  end

  def update
    if params[:id]
      @user = User.find(params[:id])
    else
      @user = User.find_by_email(cookies[:h_email])
    end

    @user.email = params[:user][:email]
    @user.first_name = params[:user][:first_name]
    @user.last_name = params[:user][:last_name]
    @user.dob = params[:user][:dob]
    @user.street_address = params[:user][:street_address]
    @user.city = params[:user][:city]
    @user.state = params[:user][:state]
    @user.zip = params[:user][:zip]
    @user.occupation = params[:user][:occupation]
    @user.how_long = params[:user][:how_long]
    @user.how_heard = params[:user][:how_heard]
    converted = Date.parse(@user.dob.to_s).strftime("%m/%y") if @user.dob


    if @user.save
      begin
        @list_id = ENV["MAILCHIMP_LIST_ID"]
        gb = Gibbon::Request.new

        gb.lists(ENV["MAILCHIMP_LIST_ID"]).members.create(body: {
          email_address: @user.email,
          status: "subscribed",
          merge_fields: {
            FNAME: @user.first_name,
            LNAME: @user.last_name,
            DOB: converted,
            ADDRESS: @user.street_address,
            CTY: @user.city,
            STATE: @user.state,
            ZIP: @user.zip,
            OCCUPATION: @user.occupation,
            HOW_LONG: @user.how_long,
            HOW_HEARD: @user.how_heard
          }
        })
        redirect_to '/refer-a-friend'
        cookies[:h_email] = { value: @user.email }
      rescue Gibbon::MailChimpError => e
        flash[:notice] = "Oops! Something went wrong. It could be that you forgot to enter some information, or that you already have an account associated with that email address. Please email vips@verilymag.com if you continue to experience issues."
        puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
        redirect_to edit_user_url(@user.id)
      end

    else
      flash[:notice] = "Oops! Something went wrong. It could be that you forgot to enter some information, or that you already have an account associated with that email address. Please email vips@verilymag.com if you continue to experience issues."
      logger.info("Error saving user with email, #{email}")
      redirect_to edit_user_url(@user.id), alert: 'Something went wrong!'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def faq
    if cookies[:h_email]
      @user = User.find_by_email(cookies[:h_email])
      @is_user = true
      @potential_user = false
      @potential_subscriber = false
    elsif cookies[:h_subscriber]
      @potential_subscriber = false
      @potential_user = false
    elsif cookies[:h_ref]
      @potential_subscriber = true
      @subscriber = Subscriber.new
    else
      @user = User.new
      @is_user = false
      @potential_user = true
      @potential_subscriber = false
    end
  end

  def swag


  end

  def redirect
    redirect_to root_path, status: 404
  end

  def logout
    cookies.delete :h_email
    redirect_to root_path
  end

  private

  def skip_first_page
    return if Rails.application.config.ended

    email = cookies[:h_email]
    if email && User.find_by_email(email)
      redirect_to '/refer-a-friend'
    else
      cookies.delete :h_email
    end
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
