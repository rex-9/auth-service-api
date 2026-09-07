# app/controllers/v1/app_installs_controller.rb

class V1::AppInstallsController < V1::ApplicationController
  # POST /v1/app_installs
  def create_install
    install = AppVersionService.create_install(
      user: current_user,
      platform: platform_session,
      number: install_params[:app_version],
      version_code: install_params[:version_code]
    )
    created = install.previously_new_record?

    render_json_response(
      status_code: created ? 201 : 200,
      message: app_install_message(
        created ? MessageService::AppInstall::CREATED : MessageService::AppInstall::UPDATED
      ),
      data: { app_install: AppInstallSerializer.new(install).serializable_hash[:data][:attributes] }
    )
  rescue ActionController::ParameterMissing, ActiveRecord::RecordInvalid => e
    error = e.respond_to?(:record) ? e.record.errors.full_messages.to_sentence : e.message

    render_json_response(
      status_code: 422,
      message: app_install_message(MessageService::AppInstall::CREATE_FAILED),
      error: error
    )
  end

  private

  def install_params
    params.require(:app_install).permit(:app_version, :version_code)
  end

  def app_install_message(key, **options)
    MessageService::AppInstall.t(key, **options)
  end
end
