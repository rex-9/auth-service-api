module MailProviders
  class ResendMailProvider
    def name
      "resend"
    end

    def deliver(message)
      Resend.api_key = ENV.fetch("RESEND_API_KEY")

      payload = {
        from: message.from,
        to: message.to,
        subject: message.subject,
        html: message.html_body,
        text: message.text_body
      }.compact

      response = Resend::Emails.send(payload)
      {
        provider_message_id: response[:id] || response["id"],
        raw: response
      }
    rescue KeyError => e
      raise Mailers::MailService::DeliveryError, "RESEND_API_KEY is missing: #{e.message}"
    rescue StandardError => e
      raise Mailers::MailService::DeliveryError, "Resend error: #{e.message}"
    end
  end
end
