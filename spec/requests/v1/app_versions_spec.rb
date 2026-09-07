require "rails_helper"

RSpec.describe "V1 App Versions API", type: :request do
  describe "GET /v1/app_versions/current" do
    it "returns an empty version payload without requiring authentication" do
      get "/v1/app_versions/current", params: { app_version: "1.0.0" }

      expect(response).to have_http_status(:ok)
      expect(response_status["message"]).to eq(I18n.t("app_version.current_fetched"))
      expect(response_data.dig("app_version", "number")).to be_nil
      expect(response_data.dig("app_version", "update_required")).to be(false)
      expect(response_data.dig("app_version", "must_update")).to be(false)
      expect(response_data.dig("app_version", "skip_premium")).to be(false)
      expect(AppInstall.count).to eq(0)
    end

    it "returns the latest live release and computed update flags" do
      create(:app_version, :published, :force, number: "1.1.0", title: "Force")
      create(
        :app_version, :published,
        number: "1.2.0",
        title: "Latest",
        ios_build_number: 90,
        android_build_number: 84
      )
      create(:app_version, number: "2.0.0", title: "Draft")
      create(:app_version, :yanked, number: "0.9.0", title: "Yanked")
      create(
        :app_version, :published,
        number: "3.0.0",
        title: "Scheduled",
        released_at: 1.day.from_now
      )

      stub_const("AppConfig::IOS_STORE_URL", "https://apps.apple.com/app/rexone")

      get "/v1/app_versions/current",
          params: { app_version: "1.0.0" },
          headers: { "X-Platform" => AuthConstants::Platform::IOS }

      expect(response).to have_http_status(:ok)
      expect(response_data.dig("app_version", "number")).to eq("1.2.0")
      expect(response_data.dig("app_version", "title")).to eq("Latest")
      expect(response_data.dig("app_version", "update_required")).to be(true)
      expect(response_data.dig("app_version", "must_update")).to be(true)
      expect(response_data.dig("app_version", "skip_premium")).to be(false)
      expect(response_data.dig("app_version", "store_url")).to eq("https://apps.apple.com/app/rexone")
      expect(response_data["app_version"]).not_to have_key("is_force_update")
      expect(response_data["app_version"]).not_to have_key("ios_build_number")
      expect(response_data["app_version"]).not_to have_key("android_build_number")
      expect(AppInstall.count).to eq(0)
    end

    it "does not require an update when the client is already on the latest live number" do
      create(:app_version, :published, :force, number: "1.1.0")
      create(:app_version, :published, number: "1.2.0")

      get "/v1/app_versions/current", params: { app_version: "1.2.0" }

      expect(response).to have_http_status(:ok)
      expect(response_data.dig("app_version", "update_required")).to be(false)
      expect(response_data.dig("app_version", "must_update")).to be(false)
      expect(response_data.dig("app_version", "skip_premium")).to be(false)
    end

    it "marks update_required without must_update when the client is behind a non-force latest" do
      create(:app_version, :published, number: "1.2.0")

      get "/v1/app_versions/current", params: { app_version: "1.0.0" }

      expect(response).to have_http_status(:ok)
      expect(response_data.dig("app_version", "update_required")).to be(true)
      expect(response_data.dig("app_version", "must_update")).to be(false)
      expect(response_data.dig("app_version", "skip_premium")).to be(false)
    end

    it "skips premium when the client marketing number is newer than the latest live release" do
      create(:app_version, :published, number: "1.2.0")
      create(:app_version, number: "2.0.0", title: "Draft")

      get "/v1/app_versions/current", params: { app_version: "1.3.0" }

      expect(response).to have_http_status(:ok)
      expect(response_data.dig("app_version", "number")).to eq("1.2.0")
      expect(response_data.dig("app_version", "update_required")).to be(false)
      expect(response_data.dig("app_version", "must_update")).to be(false)
      expect(response_data.dig("app_version", "skip_premium")).to be(true)
    end

    it "does not write an AppInstall even with a valid JWT" do
      user = create(:user)
      grant_permissions(user, "app_versions", :read)

      get "/v1/app_versions/current",
          params: { app_version: "1.4.0" },
          headers: authorization_headers(jwt_for(user))

      expect(response).to have_http_status(:ok)
      expect(AppInstall.count).to eq(0)
    end

    it "allows a signed-in user with read_app_versions" do
      user = create(:user)
      grant_permissions(user, "app_versions", :read)

      get "/v1/app_versions/current",
          params: { app_version: "1.0.0" },
          headers: authorization_headers(jwt_for(user))

      expect(response).to have_http_status(:ok)
    end

    it "forbids a signed-in user without read_app_versions" do
      user = create(:user)
      user.user_roles.destroy_all

      get "/v1/app_versions/current",
          params: { app_version: "1.0.0" },
          headers: authorization_headers(jwt_for(user))

      expect(response).to have_http_status(:forbidden)
    end

    it "ignores an invalid bearer token and still returns the check" do
      get "/v1/app_versions/current",
          params: { app_version: "1.0.0" },
          headers: { "Authorization" => "Bearer not-a-jwt" }

      expect(response).to have_http_status(:ok)
      expect(AppInstall.count).to eq(0)
    end
  end
end
