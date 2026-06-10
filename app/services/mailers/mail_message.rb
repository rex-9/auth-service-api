module Mailers
  class MailMessage
    attr_reader :to, :from, :subject, :html_body, :text_body, :headers

    def initialize(to:, from:, subject:, html_body: nil, text_body: nil, headers: {})
      @to = Array(to).compact
      @from = from
      @subject = subject
      @html_body = html_body
      @text_body = text_body
      @headers = headers
    end

    def self.from_mail(mail)
      from_header = if mail[:from].present?
        mail[:from].value
      else
        fallback_from_header
      end

      new(
        to: Array(mail.to).compact,
        from: from_header,
        subject: mail.subject,
        html_body: extract_html(mail),
        text_body: extract_text(mail),
        headers: mail.header.fields.each_with_object({}) { |field, acc| acc[field.name] = field.value.to_s }
      )
    end

    def self.fallback_from_header
      address = ENV.fetch("MAIL_FROM_ADDRESS", "no-reply@example.com")
      name = ENV.fetch("MAIL_FROM_NAME", "").strip
      return address if name.empty?

      "#{name} <#{address}>"
    end

    def self.extract_html(mail)
      return mail.html_part&.decoded if mail.multipart?

      content_type = mail.content_type.to_s
      return mail.body.decoded if content_type.include?("text/html")

      nil
    end

    def self.extract_text(mail)
      return mail.text_part&.decoded if mail.multipart?

      content_type = mail.content_type.to_s
      return mail.body.decoded if content_type.include?("text/plain")

      nil
    end
  end
end
