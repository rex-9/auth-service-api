class CustomFailure < Devise::FailureApp
  def respond
    json_error_response
  end

  def json_error_response
    self.status = determine_status_code
    self.content_type = "application/json"
    self.response_body = {
      status: {
        code: self.status,
        message: warden_options[:message] || "Unauthorized",
        error: i18n_message # Devise provides a translated message here
      }
    }.to_json
  end

  private

  def determine_status_code
    case warden_options[:action]
    when "unauthenticated"
      401
    when "invalid"
      422
    when "timeout"
      440
    else
      400 # Default bad request if other actions occur
    end
  end
end
