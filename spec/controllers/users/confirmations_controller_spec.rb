require 'rails_helper'

RSpec.describe Users::ConfirmationsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user, confirmed_at: nil) }
  let(:confirmed_user) { create(:user, confirmed_at: Time.now) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  def json_response
    JSON.parse(response.body)
  end

  describe 'GET #show' do
    context 'with valid confirmation token' do
      it 'confirms the user and redirects to the client with auth token' do
        get :show, params: { confirmation_token: user.confirmation_token }
        expect(response).to redirect_to("#{AppConfig::CLIENT_BASE_URL}/signin?auth_token=#{user.reload.jti}")
      end
    end

    context 'with invalid confirmation token' do
      it 'redirects to the client with error message' do
        get :show, params: { confirmation_token: 'invalid_token' }
        expect(response).to redirect_to("#{AppConfig::CLIENT_BASE_URL}/signin?error=Confirmation token is invalid")
      end
    end
  end

  describe 'POST #resend' do
    context 'with valid email and unconfirmed user' do
      it 'resends confirmation instructions and returns a success response' do
        post :resend, params: { email: user.email }
        expect(response).to have_http_status(:ok)
        expect(json_response['status']['code']).to eq(200)
        expect(json_response['status']['message']).to eq(Messages::VERIFICATION_EMAIL_SENT.call(user.email))
      end
    end

    context 'with confirmed user' do
      it 'returns a not found response' do
        post :resend, params: { email: confirmed_user.email }
        expect(response).to have_http_status(:not_found)
        expect(json_response['status']['code']).to eq(404)
        expect(json_response['status']['message']).to eq(Messages::EMAIL_ALREADY_CONFIRMED)
      end
    end

    context 'with non-existent email' do
      it 'returns a not found response' do
        post :resend, params: { email: 'nonexistent@example.com' }
        expect(response).to have_http_status(:not_found)
        expect(json_response['status']['code']).to eq(404)
        expect(json_response['status']['message']).to eq(Messages::USER_NOT_FOUND)
      end
    end
  end
end
