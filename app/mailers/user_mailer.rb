class UserMailer < ApplicationMailer
  def send_email_verification_mail(user)
    @user = user
    mail(
      to: @user.email,
      subject: "Your Meritbox verification code: #{@user.confirmation_code}",
      template_name: "verification_email"
    )
  end

  def send_password_reset_mail(user)
    @user = user
    @url = @user.reset_password_url
    mail(to: @user.email, subject: "Reset Passcode Instructions")
  end
end
