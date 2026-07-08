class MailController < ApplicationController
  before_action :authenticate_user!

  TEMPLATES = {
    "email_verification" => :deliver_email_verification,
    "password_reset" => :deliver_password_reset
  }.freeze

  def deliver
    delivery_method = TEMPLATES[mail_params[:type]]
    return render_json_response(status_code: 422, message: "Invalid mail payload.", error: "Unsupported email template type") unless delivery_method

    recipient = find_recipient
    return render_json_response(status_code: 404, message: "Recipient not found.") unless recipient

    send(delivery_method, recipient)
    render_json_response(status_code: 200, message: "Email delivered successfully.")
  rescue ActionController::ParameterMissing => e
    render_json_response(status_code: 422, message: "Invalid mail payload.", error: e.message)
  rescue Mailers::MailService::DeliveryError => e
    render_json_response(status_code: 422, message: "Failed to deliver email.", error: e.message)
  end

  private

  def mail_params
    @mail_params ||= params.require(:mail).permit(:type, :user_id, :email)
  end

  def find_recipient
    return User.find_by(id: mail_params[:user_id]) if mail_params[:user_id].present?
    return User.find_by(email: mail_params[:email].to_s.downcase) if mail_params[:email].present?

    current_user
  end

  def deliver_email_verification(user)
    user.generate_confirmation_code
    user.save!
    UserMailer.send_email_verification_mail(user).deliver_now
  end

  def deliver_password_reset(user)
    user.send_reset_password_instructions
  end
end
