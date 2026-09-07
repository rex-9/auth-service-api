class V1::Admin::AppVersionsController < V1::ApplicationController
  before_action :super_admin_required!
  before_action :set_active_version, only: %i[show update discard read_installs]
  before_action :set_version_including_discarded, only: :undiscard

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  # GET /v1/admin/app_versions
  def index
    versions = AppVersion.with_install_counts
    versions = versions.where(status: params[:status]) if params[:status].present?
    versions = sort(versions, columns: SortConstants::Columns::APP_VERSION)
    pagy, records = pagy(versions)

    render_json_response(
      status_code: 200,
      message: app_version_message(MessageService::AppVersion::FETCHED),
      data: AppVersionAdminSerializer.paginated(records, pagy),
      pagy: pagy
    )
  end

  # GET /v1/admin/app_versions/discarded
  def read_discarded
    versions = AppVersion.with_discarded.discarded.with_install_counts
    versions = sort(versions, columns: SortConstants::Columns::APP_VERSION, default_column: :discarded_at)
    pagy, records = pagy(versions)

    render_json_response(
      status_code: 200,
      message: app_version_message(MessageService::AppVersion::DISCARDED_FETCHED),
      data: AppVersionAdminSerializer.paginated(records, pagy),
      pagy: pagy
    )
  end

  # GET /v1/admin/app_versions/:id
  def show
    render_json_response(
      status_code: 200,
      message: app_version_message(MessageService::AppVersion::FETCHED),
      data: AppVersionAdminSerializer.new(@version).serializable_hash[:data][:attributes]
    )
  end

  # POST /v1/admin/app_versions
  def create
    version = AppVersion.new(version_params)
    version.status ||= AppVersionConstants::Status::DRAFT

    if version.save
      render_json_response(
        status_code: 201,
        message: app_version_message(MessageService::AppVersion::CREATED),
        data: AppVersionAdminSerializer.new(version).serializable_hash[:data][:attributes]
      )
    else
      render_json_response(
        status_code: 422,
        message: app_version_message(MessageService::AppVersion::CREATE_FAILED),
        error: version.errors.full_messages.to_sentence
      )
    end
  end

  # PATCH/PUT /v1/admin/app_versions/:id
  def update
    if @version.update(version_params)
      render_json_response(
        status_code: 200,
        message: app_version_message(MessageService::AppVersion::UPDATED),
        data: AppVersionAdminSerializer.new(@version).serializable_hash[:data][:attributes]
      )
    else
      render_json_response(
        status_code: 422,
        message: app_version_message(MessageService::AppVersion::UPDATE_FAILED),
        error: @version.errors.full_messages.to_sentence
      )
    end
  end

  # POST /v1/admin/app_versions/:id/discard
  def discard
    @version.discard!

    render_json_response(
      status_code: 200,
      message: app_version_message(MessageService::AppVersion::DISCARDED)
    )
  end

  # POST /v1/admin/app_versions/:id/undiscard
  def undiscard
    @version.undiscard!

    render_json_response(
      status_code: 200,
      message: app_version_message(MessageService::AppVersion::RESTORED),
      data: AppVersionAdminSerializer.new(@version).serializable_hash[:data][:attributes]
    )
  end

  # GET /v1/admin/app_versions/:id/installs
  def read_installs
    installs = @version.app_installs.includes(:user)
    installs = sort(installs, columns: SortConstants::Columns::APP_INSTALL, default_column: :last_seen_at)
    pagy, records = pagy(installs)

    render_json_response(
      status_code: 200,
      message: app_install_message(MessageService::AppInstall::FETCHED),
      data: AppInstallAdminSerializer.paginated(records, pagy),
      pagy: pagy
    )
  end

  private

  def set_active_version
    @version = AppVersion.find(params[:id])
  end

  def set_version_including_discarded
    @version = AppVersion.with_discarded.find(params[:id])
  end

  def version_params
    permitted = params.require(:app_version).permit(
      :number,
      :title,
      :description,
      :is_force_update,
      :status,
      :ios_build_number,
      :android_build_number
    )

    %i[ios_build_number android_build_number].each do |key|
      permitted[key] = nil if permitted[key].blank?
    end

    permitted
  end

  def render_not_found
    render_json_response(
      status_code: 404,
      message: app_version_message(MessageService::AppVersion::NOT_FOUND),
      error: app_version_message(MessageService::AppVersion::NOT_FOUND)
    )
  end

  def app_version_message(key, **options)
    MessageService::AppVersion.t(key, **options)
  end

  def app_install_message(key, **options)
    MessageService::AppInstall.t(key, **options)
  end
end
