class V1::Admin::UserVersionsController < V1::ApplicationController
  before_action :super_admin_required!

  # GET /v1/admin/versions/user_versions
  def index
    records = UserVersion.includes(:user)
    records = records.where(platform: params[:platform]) if params[:platform].present?
    records = sort(records, columns: SortConstants::Columns::USER_VERSION, default_column: :last_seen_at)
    pagy, page_records = pagy(records)

    render_json_response(
      status_code: 200,
      message: user_version_message(MessageService::UserVersion::FETCHED),
      data: UserVersionAdminSerializer.paginated(page_records, pagy),
      pagy: pagy
    )
  end

  private

  def user_version_message(key, **options)
    MessageService::UserVersion.t(key, **options)
  end
end
