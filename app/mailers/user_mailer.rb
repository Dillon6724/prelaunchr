class UserMailer < ActionMailer::Base
  default from: "Harry's <ohhello@verilymag.com>"

  def signup_email(user)
    @user = user
    @twitter_message = "Verily Magazine. Less of who you should be, more of who you are."

    mail(:to => user.email, :subject => "Thanks for signing up!")
  end
end
