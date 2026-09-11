class V1::Admin::Payment::TransactionsController < V1::ApplicationController
  # GET /v1/admin/payment/transactions
  def index
    transactions = ::Payment::Transaction.includes(:user, :product)
    transactions = transactions.where(status: params[:status]) if params[:status].present?
    transactions = transactions.where(currency: params[:currency]) if params[:currency].present?
    transactions = transactions.where(product_id: params[:product_id]) if params[:product_id].present?
    transactions = transactions.where(user_id: params[:user_id]) if params[:user_id].present?
    transactions = search(transactions)
    transactions = sort(
      transactions,
      columns: SortConstants::Columns::TRANSACTION,
      default_column: "created_at"
    )
    pagy, records = pagy(:offset, transactions, limit: params[:limit])

    render_json_response(
      status_code: 200,
      message: payment_message(MessageService::Payment::TRANSACTIONS_FETCHED),
      data: ::Payment::TransactionSerializer.paginated(records, pagy),
      pagy: pagy
    )
  end

  # GET /v1/admin/payment/transactions/:id
  def show
    transaction = ::Payment::Transaction.includes(:user, :product).find(params[:id])

    render_json_response(
      status_code: 200,
      message: payment_message(MessageService::Payment::TRANSACTION_FETCHED),
      data: ::Payment::TransactionSerializer.new(transaction).serializable_hash[:data]
    )
  end

  private

  def search(scope)
    return scope if params[:search].blank?

    term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:search].strip)}%"
    scope.left_joins(:user, :product).where(
      "users.email ILIKE :term OR users.username ILIKE :term OR payment_products.name ILIKE :term " \
      "OR payment_transactions.stripe_payment_intent_id ILIKE :term OR payment_transactions.stripe_charge_id ILIKE :term",
      term: term
    )
  end

  def payment_message(key, **options)
    MessageService::Payment.t(key, **options)
  end
end
