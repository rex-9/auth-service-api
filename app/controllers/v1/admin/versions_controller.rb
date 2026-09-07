class V1::Admin::VersionsController < V1::ApplicationController
  before_action :super_admin_required!
  before_action :set_active_version, only: %i[show update discard read_user_versions]
  before_action :set_version_including_discarded, only: :undiscard

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  # GET /v1/admin/versions
  def index
    versions = Version.with_install_counts
    versions = versions.where(status: params[:status]) if params[:status].present?
    versions = sort(versions, columns: SortConstants::Columns::VERSION)
    pagy, records = pagy(versions)

    render_json_response(
      status_code: 200,
      message: version_message(MessageService::Version::FETCHED),
      data: VersionAdminSerializer.paginated(records, pagy),
      pagy: pagy
    )
  end

  # GET /v1/admin/versions/discarded
  def read_discarded
    versions = Version.with_discarded.discarded.with_install_counts
    versions = sort(versions, columns: SortConstants::Columns::VERSION, default_column: :discarded_at)
    pagy, records = pagy(versions)

    render_json_response(
      status_code: 200,
      message: version_message(MessageService::Version::DISCARDED_FETCHED),
      data: VersionAdminSerializer.paginated(records, pagy),
      pagy: pagy
    )
  end

  # GET /v1/admin/versions/:id
  def show
    render_json_response(
      status_code: 200,
      message: version_message(MessageService::Version::FETCHED),
      data: VersionAdminSerializer.new(@version).serializable_hash[:data][:attributes]
    )
  end

  # POST /v1/admin/versions
  def create
    version = Version.new(version_params)
    version.status ||= VersionConstants::Status::DRAFT

    if version.save
      render_json_response(
        status_code: 201,
        message: version_message(MessageService::Version::CREATED),
        data: VersionAdminSerializer.new(version).serializable_hash[:data][:attributes]
      )
    else
      render_json_response(
        status_code: 422,
        message: version_message(MessageService::Version::CREATE_FAILED),
        error: version.errors.full_messages.to_sentence
      )
    end
  end

  # PUT /v1/admin/versions/:id
  def update
    if @version.update(version_params)
      render_json_response(
        status_code: 200,
        message: version_message(MessageService::Version::UPDATED),
        data: VersionAdminSerializer.new(@version).serializable_hash[:data][:attributes]
      )
    else
      render_json_response(
        status_code: 422,
        message: version_message(MessageService::Version::UPDATE_FAILED),
        error: @version.errors.full_messages.to_sentence
      )
    end
  end

  # POST /v1/admin/versions/:id/discard
  def discard
    @version.discard!

    render_json_response(
      status_code: 200,
      message: version_message(MessageService::Version::DISCARDED)
    )
  end

  # POST /v1/admin/versions/:id/undiscard
  def undiscard
    @version.undiscard!

    render_json_response(
      status_code: 200,
      message: version_message(MessageService::Version::RESTORED),
      data: VersionAdminSerializer.new(@version).serializable_hash[:data][:attributes]
    )
  end

  # GET /v1/admin/versions/:id/user_versions
  def read_user_versions
    records = @version.user_versions.includes(:user)
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

  def set_active_version
    @version = Version.find(params[:id])
  end

  def set_version_including_discarded
    @version = Version.with_discarded.find(params[:id])
  end

  def version_params
    permitted = params.require(:version).permit(
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
      message: version_message(MessageService::Version::NOT_FOUND),
      error: version_message(MessageService::Version::NOT_FOUND)
    )
  end

  def version_message(key, **options)
    MessageService::Version.t(key, **options)
  end

  def user_version_message(key, **options)
    MessageService::UserVersion.t(key, **options)
  end
end
