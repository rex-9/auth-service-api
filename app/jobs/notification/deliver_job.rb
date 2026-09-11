class Notification::DeliverJob < ApplicationJob
  class DeliveryError < StandardError; end

  queue_as :notifications

  retry_on DeliveryError,
           EmailService::Error,
           wait: :polynomially_longer,
           attempts: 5 do |job, error|
    operation = job.arguments.first&.with_indifferent_access&.dig(:operation)
    NotificationService::OperationTracker.transition(
      operation: operation,
      status: NotificationConstants::OperationStatus::FAILED,
      error: error.message
    ) if operation
  end

  def perform(channel:, payload:, operation: nil)
    track(operation, NotificationConstants::OperationStatus::PROCESSING)

    result = case channel.to_sym
    when :socket
      SocketService::Client.broadcast(**payload.symbolize_keys)
    when :push
      PushNotiService::Client.send_to_user(**payload.symbolize_keys)
    when :email
      deliver_email(payload.symbolize_keys)
    else
      raise ArgumentError, "Unsupported notification channel: #{channel}"
    end

    raise DeliveryError, "#{channel} delivery failed" unless result

    track(operation, NotificationConstants::OperationStatus::COMPLETED)
  end

  private

  def track(operation, status)
    return unless operation

    NotificationService::OperationTracker.transition(
      operation: operation,
      status: status
    )
  end

  def deliver_email(payload)
    if payload[:template_id].present?
      EmailService::Client.send_template(**payload)
    else
      EmailService::Client.send_email(**payload)
    end
  end
end
