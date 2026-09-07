# app/controllers/v1/app_versions_controller.rb

class V1::AppVersionsController < V1::ApplicationController
  skip_before_action :authenticate_user!, only: [ :read_current ]
  skip_before_action :enforce_active_platform_session!, only: [ :read_current ]

  # GET /v1/app_versions/current
  def read_current
    result = AppVersionService.check(
      app_version: params[:app_version],
      platform: platform_session
    )

    render_json_response(
      status_code: 200,
      message: app_version_message(MessageService::AppVersion::CURRENT_FETCHED),
      data: { app_version: check_payload(result) }
    )
  end

  private

  def check_payload(result)
    extras = {
      update_required: result.update_required,
      must_update: result.must_update,
      skip_premium: result.skip_premium,
      store_url: result.store_url
    }

    if result.latest
      AppVersionSerializer.new(result.latest, params: extras)
        .serializable_hash[:data][:attributes]
    else
      AppVersionService::EMPTY_CATALOG.merge(extras)
    end
  end

  def app_version_message(key, **options)
    MessageService::AppVersion.t(key, **options)
  end
end
