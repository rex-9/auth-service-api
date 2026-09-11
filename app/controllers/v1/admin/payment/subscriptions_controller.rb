class V1::Admin::Payment::SubscriptionsController < V1::ApplicationController
  # GET /v1/admin/payment/subscriptions
  def index
    subscriptions = ::Payment::Subscription.includes(:user, :product)
    subscriptions = subscriptions.where(status: params[:status]) if params[:status].present?
    subscriptions = subscriptions.where(interval: params[:interval]) if params[:interval].present?
    subscriptions = subscriptions.where(product_id: params[:product_id]) if params[:product_id].present?
    subscriptions = subscriptions.where(user_id: params[:user_id]) if params[:user_id].present?
    unless params[:cancel_at_period_end].nil?
      subscriptions = subscriptions.where(cancel_at_period_end: ActiveModel::Type::Boolean.new.cast(params[:cancel_at_period_end]))
    end
    subscriptions = search(subscriptions)
    subscriptions = sort(
      subscriptions,
      columns: SortConstants::Columns::SUBSCRIPTION,
      default_column: "created_at"
    )
    pagy, records = pagy(:offset, subscriptions, limit: params[:limit])

    render_json_response(
      status_code: 200,
      message: payment_message(MessageService::Payment::SUBSCRIPTIONS_FETCHED),
      data: ::Payment::SubscriptionSerializer.paginated(records, pagy),
      pagy: pagy
    )
  end

  # GET /v1/admin/payment/subscriptions/:id
  def show
    subscription = ::Payment::Subscription.includes(:user, :product).find(params[:id])

    render_json_response(
      status_code: 200,
      message: payment_message(MessageService::Payment::SUBSCRIPTION_FETCHED),
      data: ::Payment::SubscriptionSerializer.new(subscription).serializable_hash[:data]
    )
  end

  private

  def search(scope)
    return scope if params[:search].blank?

    term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:search].strip)}%"
    scope.left_joins(:user, :product).where(
      "users.email ILIKE :term OR users.username ILIKE :term OR payment_products.name ILIKE :term " \
      "OR payment_subscriptions.stripe_subscription_id ILIKE :term",
      term: term
    )
  end

  def payment_message(key, **options)
    MessageService::Payment.t(key, **options)
  end
end
