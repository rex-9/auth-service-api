namespace :mail do
  desc "Send a real test email through configured provider. Usage: rake mail:send_test TO=email@example.com"
  task send_test: :environment do
    to = ENV["TO"].to_s.strip

    if to.empty?
      abort "TO is required. Example: rake mail:send_test TO=you@example.com"
    end

    from_address = ENV.fetch("MAIL_FROM_ADDRESS", "no-reply@example.com")
    from_name = ENV.fetch("MAIL_FROM_NAME", "").strip
    from = from_name.empty? ? from_address : "#{from_name} <#{from_address}>"

    message = Mailers::MailMessage.new(
      to: [to],
      from: from,
      subject: "Mail Provider Test (#{ENV.fetch('MAIL_MAILER', 'resend')})",
      html_body: "<p>This is a real test email from auth-service-api.</p>",
      text_body: "This is a real test email from auth-service-api."
    )

    result = Mailers::ProviderRegistry.build_service.deliver(message)
    provider_message_id = result.is_a?(Hash) ? result[:provider_message_id] || result["provider_message_id"] : nil

    puts "Mail sent successfully"
    puts "provider=#{ENV.fetch('MAIL_MAILER', 'resend')}"
    puts "to=#{to}"
    puts "provider_message_id=#{provider_message_id}"
  rescue StandardError => e
    abort "Mail send failed: #{e.message}"
  end
end
