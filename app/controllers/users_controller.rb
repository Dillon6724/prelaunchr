class UsersController < ApplicationController
  before_filter :skip_first_page, only: :new

  # will need to uncomment this method before launching in production
  # before_filter :handle_ip, only: :create

  def new
    @bodyId = 'home'
    @is_mobile = mobile_device?

    if params[:REF]
      cookies[:h_ref] = { value: params[:REF]}
      redirect_to new_subscriber_url and return
    end

    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    ref_code = cookies[:h_ref].downcase if ref_code
    email = params[:user][:email]
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

  def refer
    @bodyId = 'refer'
    @is_mobile = mobile_device?

    @user = User.find_by_email(cookies[:h_email] || params[:user][:email])

    respond_to do |format|
      if @user.nil?
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
    @user.age = params[:user][:age]
    @user.street_address = params[:user][:street_address]
    @user.city = params[:user][:city]
    @user.state = params[:user][:state]
    @user.zip = params[:user][:zip]
    @user.occupation = params[:user][:occupation]
    @user.how_long = params[:user][:how_long]
    @user.how_heard = params[:user][:how_heard]

    if @user.save
      cookies[:h_email] = { value: @user.email }
      redirect_to '/refer-a-friend'
    else
      logger.info("Error saving user with email, #{email}")
      redirect_to root_path, alert: 'Something went wrong!'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def faq
    @user = User.find_by_email(cookies[:h_email])
  end

  def redirect
    redirect_to root_path, status: 404
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
