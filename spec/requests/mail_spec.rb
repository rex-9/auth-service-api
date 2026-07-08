require "rails_helper"

RSpec.describe "Mail delivery", type: :request do
  let(:user) do
    create(
      :user,
      email: "mail-user@example.com",
      username: "mailuser",
      password: "password",
      password_confirmation: "password"
    )
  end

  let(:token) { AppConfig::JWT_TOKEN.call(user) }
  let(:headers) do
    {
      "Authorization" => "Bearer #{token}",
      "X-Platform" => "web"
    }
  end

  before do
    user
    ActionMailer::Base.deliveries.clear
    PASSWORD_REDIS.set("active_session:user:#{user.id}:web", token, ex: 1.week.to_i)
  end

  after do
    PASSWORD_REDIS.del("active_session:user:#{user.id}:web")
  end

  it "delivers an email verification message to the current user" do
    expect(UserMailer).to receive(:send_email_verification_mail)
      .with(an_instance_of(User))
      .and_call_original

    post "/mail/deliver", params: { mail: { type: "email_verification" } }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("status", "message")).to eq("Email delivered successfully.")
    expect(ActionMailer::Base.deliveries.last[:from].display_names).to eq([ ENV.fetch("MAIL_FROM_NAME", "") ])
  end

  it "delivers a password reset message to the current user" do
    expect_any_instance_of(User).to receive(:send_reset_password_instructions).and_call_original

    post "/mail/deliver", params: { mail: { type: "password_reset" } }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("status", "message")).to eq("Email delivered successfully.")
  end

  it "rejects unsupported template types" do
    post "/mail/deliver", params: { mail: { type: "unknown" } }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
