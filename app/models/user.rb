require 'users_helper'

class User < ActiveRecord::Base
  belongs_to :referrer, class_name: 'User', foreign_key: 'referrer_id'
  has_many :referrals, class_name: 'User', foreign_key: 'referrer_id'
  has_many :subscribers, class_name: 'Subscriber', foreign_key: 'referrer_id'

  validates :email, presence: true, uniqueness: true, format: {
    with: /\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/i,
    message: 'Invalid email format.'
  }
  validates :referral_code, uniqueness: true

  before_create :create_referral_code
  # after_create :send_welcome_email

  REFERRAL_STEPS = [
    {
      'count' => 5,
      'html' => 'Stickers and full VIP membership',
      'class' => 'two'
    },
    {
      'count' => 10,
      'html' => 'Verily tote bag with inspirational quote',
      'class' => 'three'
    },
    {
      'count' => 25,
      'html' => 'Verily journal with inspirational quote',
      'class' => 'four'
    },
    {
      'count' => 50,
      'html' => 'Three small 5” x 5” Daily Dose wall prints',
      'class' => 'five'
    }
  ]

  private

  def create_referral_code
    self.referral_code = UsersHelper.unused_referral_code
  end

  def send_welcome_email
    UserMailer.delay.signup_email(self)
  end
end
