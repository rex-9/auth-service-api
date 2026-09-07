require "rails_helper"

RSpec.describe "V1 App Installs API", type: :request do
  let(:user) { create(:user) }
  let(:token) { jwt_for(user) }
  let(:headers) { authorization_headers(token, platform: AuthConstants::Platform::ANDROID) }

  before do
    allow(CacheService).to receive(:read).and_return(token)
    allow(CacheService).to receive(:write)
    grant_permissions(user, "app_installs", :create)
  end

  describe "POST /v1/app_installs" do
    it "requires authentication" do
      post "/v1/app_installs", params: { app_install: { app_version: "1.4.0" } }

      expect(response).to have_http_status(:unauthorized)
      expect(AppInstall.count).to eq(0)
    end

    it "creates an AppInstall for the current user and platform" do
      version = create(:app_version, :published, number: "1.4.0")

      post "/v1/app_installs",
           params: { app_install: { app_version: "1.4.0", version_code: 42 } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:created)
      expect(response_status["message"]).to eq(I18n.t("app_install.created"))
      install = user.app_installs.find_by!(platform: AuthConstants::Platform::ANDROID)
      expect(install).to have_attributes(
        number: "1.4.0",
        build_number: 42,
        app_version_id: version.id
      )
      expect(response_data.dig("app_install", "number")).to eq("1.4.0")
      expect(response_data.dig("app_install", "build_number")).to eq(42)
    end

    it "updates the existing install for the same user and platform" do
      version = create(:app_version, :published, number: "1.5.0")
      existing = user.app_installs.create!(
        platform: AuthConstants::Platform::ANDROID,
        number: "1.4.0",
        build_number: 10,
        last_seen_at: 1.day.ago
      )

      post "/v1/app_installs",
           params: { app_install: { app_version: "1.5.0", version_code: 50 } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response_status["message"]).to eq(I18n.t("app_install.updated"))
      expect(user.app_installs.count).to eq(1)
      expect(existing.reload).to have_attributes(
        number: "1.5.0",
        build_number: 50,
        app_version_id: version.id
      )
    end

    it "requires create_app_installs" do
      user.user_roles.destroy_all
      create(:app_version, :published, number: "1.4.0")

      post "/v1/app_installs",
           params: { app_install: { app_version: "1.4.0" } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:forbidden)
      expect(AppInstall.count).to eq(0)
    end

    it "rejects an invalid marketing number" do
      post "/v1/app_installs",
           params: { app_install: { app_version: "not-a-version" } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(AppInstall.count).to eq(0)
    end
  end
end
