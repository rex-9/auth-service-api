require "rails_helper"

RSpec.describe "V1 Admin App Versions API", type: :request do
  let(:admin) { create(:user) }
  let(:token) { jwt_for(admin) }
  let(:headers) { authorization_headers(token) }

  before do
    allow(CacheService).to receive(:read).and_return(token)
    allow(CacheService).to receive(:write)
    grant_admin_role(admin)
    grant_admin_permissions(admin, "app_versions", :read, :create, :update, :delete)
  end

  describe "GET /v1/admin/app_versions" do
    it "lists versions for admins" do
      create(:app_version, :published, number: "1.2.0", title: "Live")
      create(:app_version, number: "1.3.0", title: "Draft")

      get "/v1/admin/app_versions", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_status["message"]).to eq(I18n.t("app_version.fetched"))
      expect(response_data.size).to eq(2)
    end

    it "filters versions by status" do
      create(:app_version, :published, number: "1.2.0")
      create(:app_version, number: "1.3.0")

      get "/v1/admin/app_versions", params: { status: "published" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_data.size).to eq(1)
      expect(response_data.first.dig("attributes", "number")).to eq("1.2.0")
    end

    it "rejects non-admin users even with read_app_versions" do
      user = create(:user)
      user_token = jwt_for(user)
      grant_permissions(user, "app_versions", :read)
      allow(CacheService).to receive(:read).and_return(user_token)

      get "/v1/admin/app_versions", headers: authorization_headers(user_token)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /v1/admin/app_versions/:id" do
    it "returns version fields including force-update and build numbers" do
      version = create(
        :app_version, :published, :force,
        number: "1.4.0",
        title: "Force",
        ios_build_number: 90,
        android_build_number: 84
      )

      get "/v1/admin/app_versions/#{version.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_data).to include(
        "number" => "1.4.0",
        "title" => "Force",
        "is_force_update" => true,
        "ios_build_number" => 90,
        "android_build_number" => 84,
        "install_count" => 0
      )
      expect(response_data).not_to have_key("must_update")
      expect(response_data).not_to have_key("update_required")
    end

    it "returns 404 for a missing version" do
      get "/v1/admin/app_versions/#{SecureRandom.uuid}", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(response_status["message"]).to eq(I18n.t("app_version.not_found"))
    end
  end

  describe "POST /v1/admin/app_versions" do
    it "creates a draft version and localizes the message" do
      post "/v1/admin/app_versions",
           params: { app_version: { number: "2.0.0", title: "Next" } },
           headers: headers.merge("X-Locale" => "my"),
           as: :json

      expect(response).to have_http_status(:created)
      expect(response_status["message"]).to eq(I18n.t("app_version.created", locale: :my))
      expect(response_data).to include("number" => "2.0.0", "title" => "Next", "status" => "draft")
    end

    it "stamps released_at when creating as published" do
      post "/v1/admin/app_versions",
           params: { app_version: { number: "2.0.0", title: "Live", status: "published" } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:created)
      expect(response_data["status"]).to eq("published")
      expect(response_data["released_at"]).to be_present
    end

    it "rejects an invalid semver" do
      post "/v1/admin/app_versions",
           params: { app_version: { number: "2.0", title: "Bad" } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response_status["message"]).to eq(I18n.t("app_version.create_failed"))
    end
  end

  describe "PATCH /v1/admin/app_versions/:id" do
    it "updates version fields" do
      version = create(:app_version, number: "1.0.0", title: "Old")

      patch "/v1/admin/app_versions/#{version.id}",
            params: { app_version: { title: "New", is_force_update: true } },
            headers: headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response_data).to include("title" => "New", "is_force_update" => true)
    end
  end

  describe "discard and restore" do
    it "hides discarded rows from the active list and returns them from the recycle bin" do
      active = create(:app_version, number: "1.0.0")
      discarded = create(:app_version, number: "0.9.0")
      discarded.discard!

      get "/v1/admin/app_versions", headers: headers

      expect(response_data.map { |record| record.dig("attributes", "id") }).to include(active.id)
      expect(response_data.map { |record| record.dig("attributes", "id") }).not_to include(discarded.id)

      get "/v1/admin/app_versions/discarded", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_status["message"]).to eq(I18n.t("app_version.discarded_fetched"))
      expect(response_data.first.dig("attributes", "id")).to eq(discarded.id)
    end

    it "discards and restores a version" do
      version = create(:app_version, number: "1.0.0")

      post "/v1/admin/app_versions/#{version.id}/discard", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_status["message"]).to eq(I18n.t("app_version.discarded"))
      expect(AppVersion.find_by(id: version.id)).to be_nil

      post "/v1/admin/app_versions/#{version.id}/undiscard", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_status["message"]).to eq(I18n.t("app_version.restored"))
      expect(response_data["id"]).to eq(version.id)
      expect(AppVersion.find(version.id)).to be_kept
    end
  end

  describe "install_count and installs" do
    it "returns the number of current snapshots linked to the version" do
      version = create(:app_version, :published, number: "1.4.0")
      other = create(:app_version, :published, number: "1.5.0")
      ios_user = create(:user)
      android_user = create(:user)

      ios_user.app_installs.create!(
        platform: AuthConstants::Platform::IOS,
        number: "1.4.0",
        app_version: version,
        last_seen_at: 2.hours.ago
      )
      android_user.app_installs.create!(
        platform: AuthConstants::Platform::ANDROID,
        number: "1.4.0",
        app_version: version,
        last_seen_at: 1.hour.ago
      )
      create(:user).app_installs.create!(
        platform: AuthConstants::Platform::WEB,
        number: "1.5.0",
        app_version: other,
        last_seen_at: Time.current
      )

      get "/v1/admin/app_versions", headers: headers

      listed = response_data.find { |record| record.dig("attributes", "id") == version.id }
      expect(listed.dig("attributes", "install_count")).to eq(2)

      get "/v1/admin/app_versions/#{version.id}", headers: headers

      expect(response_data["install_count"]).to eq(2)
    end

    it "lists installs for a version newest first" do
      version = create(:app_version, :published, number: "1.4.0")
      older_user = create(:user, email: "older@example.com")
      newer_user = create(:user, email: "newer@example.com")
      older_user.app_installs.create!(
        platform: AuthConstants::Platform::IOS,
        number: "1.4.0",
        app_version: version,
        last_seen_at: 2.days.ago
      )
      newer_user.app_installs.create!(
        platform: AuthConstants::Platform::ANDROID,
        number: "1.4.0",
        app_version: version,
        last_seen_at: 1.hour.ago
      )

      get "/v1/admin/app_versions/#{version.id}/installs", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response_status["message"]).to eq(I18n.t("app_install.fetched"))
      expect(response_data.size).to eq(2)
      expect(response_data.first.dig("attributes")).to include(
        "user_email" => "newer@example.com",
        "platform" => "android",
        "number" => "1.4.0"
      )
    end
  end
end
