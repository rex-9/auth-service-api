require "rails_helper"

RSpec.describe Notification::DeliverJob, type: :job do
  it "delivers socket and push payloads through their clients" do
    allow(SocketService::Client).to receive(:broadcast).and_return(true)
    allow(PushNotiService::Client).to receive(:send_to_user).and_return(true)

    described_class.perform_now(
      channel: "socket",
      payload: { "user_id" => "1", "message" => "Hi", "clients" => %w[web mobile] }
    )
    described_class.perform_now(channel: :push, payload: { "user_id" => "1", "title" => "Hi", "body" => "Body" })

    expect(SocketService::Client).to have_received(:broadcast).with(
      user_id: "1",
      message: "Hi",
      clients: %w[web mobile]
    )
    expect(PushNotiService::Client).to have_received(:send_to_user).with(user_id: "1", title: "Hi", body: "Body")
  end

  it "chooses template or plain email delivery from the payload" do
    allow(EmailService::Client).to receive(:send_template).and_return(true)
    allow(EmailService::Client).to receive(:send_email).and_return(true)

    described_class.perform_now(channel: :email, payload: { to: "a@example.com", template_id: "welcome" })
    described_class.perform_now(channel: :email, payload: { to: "a@example.com", subject: "Hi", body: "Body" })

    expect(EmailService::Client).to have_received(:send_template).with(to: "a@example.com", template_id: "welcome")
    expect(EmailService::Client).to have_received(:send_email).with(to: "a@example.com", subject: "Hi", body: "Body")
  end

  it "schedules a retry for a false provider result" do
    allow(SocketService::Client).to receive(:broadcast).and_return(false)
    expect do
      described_class.perform_now(channel: :socket, payload: { user_id: "1" })
    end.to have_enqueued_job(described_class).with(channel: :socket, payload: { user_id: "1" })
  end

  it "rejects unsupported channels" do
    expect do
      described_class.perform_now(channel: :sms, payload: {})
    end.to raise_error(ArgumentError, "Unsupported notification channel: sms")
  end

  it "advances a tracked provider delivery from processing to completed" do
    user = create(:user)
    allow(PushNotiService::Client).to receive(:send_to_user).and_return(true)
    allow(SocketService::Client).to receive(:broadcast).and_return(true)
    operation = {
      user_id: user.id,
      operation_id: "notification_delivery:dispatch-id:push",
      operation_type: NotificationConstants::OperationType::NOTIFICATION_DELIVERY,
      title: "Delivery",
      message: "Delivery status",
      link: "/notifications",
      data: { channel: NotificationConstants::Channel::PUSH }
    }

    described_class.perform_now(
      channel: :push,
      payload: { user_id: user.id, title: "Hi", body: "Body" },
      operation: operation
    )

    notification = UserNotification.find_by!(operation_id: operation[:operation_id])
    expect(notification.operation_status).to eq(NotificationConstants::OperationStatus::COMPLETED)
    expect(notification.link).to eq("/notifications")
  end
end
