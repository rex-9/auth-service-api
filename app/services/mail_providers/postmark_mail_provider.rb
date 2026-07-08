module MailProviders
  class PostmarkMailProvider
    def name
      "postmark"
    end

    def deliver(message)
      token = ENV.fetch("POSTMARK_TOKEN")
      client = Postmark::ApiClient.new(token)

      payload = {
        from: message.from,
        to: message.to.join(","),
        subject: message.subject,
        html_body: message.html_body,
        text_body: message.text_body,
        message_stream: "outbound"
      }.compact

      response = client.deliver(payload)
      {
        provider_message_id: response[:message_id] || response["MessageID"],
        raw: response
      }
    rescue KeyError => e
      raise Mailers::MailService::DeliveryError, "POSTMARK_TOKEN is missing: #{e.message}"
    rescue StandardError => e
      raise Mailers::MailService::DeliveryError, "Postmark error: #{e.message}"
    end
  end
end
