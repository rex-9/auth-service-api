require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user, password: 'password', confirmed_at: Time.now) }
  let(:unconfirmed_user) { create(:user, password: 'password', confirmed_at: nil) }
  let(:google_user_info) { { 'email' => 'google@example.com', 'name' => 'Google User', 'picture' => 'https://google_picture_url' } }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  def json_response
    JSON.parse(response.body)
  end

  describe 'POST #create' do
    context 'with valid email and password' do
      it 'returns a success response' do
        post :create, params: { user: { email: user.email, password: 'password' } }
        expect(response).to have_http_status(:ok)
        expect(json_response['status']['code']).to eq(200)
        expect(json_response['data']['user']['email']).to eq(user.email)
      end
    end

    context 'with unconfirmed email' do
      it 'sends confirmation instructions' do
        post :create, params: { user: { email: unconfirmed_user.email, password: 'password' } }
        expect(response).to have_http_status(:ok)
        expect(json_response['status']['code']).to eq(200)
        expect(json_response['status']['message']).to eq(Messages::VERIFICATION_EMAIL_SENT.call(unconfirmed_user.email))
      end
    end

    context 'with invalid password' do
      it 'returns an unauthorized response' do
        post :create, params: { user: { email: user.email, password: 'wrong_password' } }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['status']['code']).to eq(401)
        expect(json_response['status']['message']).to eq(Messages::FAILED_TO_SIGN_IN)
      end
    end

    context 'with email registered with Google' do
      let!(:google_user) { create(:user, email: google_user_info['email'], provider: 'google', password: 'password', password_confirmation: 'password', confirmed_at: Time.now) }
      it 'returns an unauthorized response' do
        post :create, params: { user: { email: google_user.email, password: 'password' } }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['status']['code']).to eq(401)
        expect(json_response['status']['message']).to eq(Messages::FAILED_TO_SIGN_IN)
        expect(json_response['status']['error']).to eq(Messages::USER_ALREADY_REGISTERED_WITH_GOOGLE.call(google_user.email))
      end
    end

    context 'with non-existent email' do
      it 'returns an unauthorized response' do
        post :create, params: { user: { email: 'nonexistent@example.com', password: 'password' } }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['status']['code']).to eq(401)
        expect(json_response['status']['message']).to eq(Messages::FAILED_TO_SIGN_IN)
        expect(json_response['status']['error']).to eq(Messages::USER_NOT_FOUND)
      end
    end
  end

  describe 'POST #token_sign_in' do
    let(:token) { 'valid_token' }

    before do
      allow(Warden::JWTAuth::UserEncoder).to receive(:new).and_return(double(call: [ token, {} ]))
    end

    context 'with valid token' do
      it 'returns a success response' do
        post :token_sign_in, params: { token: user.jti }
        expect(response).to have_http_status(:ok)
        expect(json_response['status']['code']).to eq(200)
        expect(json_response['data']['user']['email']).to eq(user.email)
      end
    end

    context 'with invalid token' do
      it 'returns an unauthorized response' do
        post :token_sign_in, params: { token: 'invalid_token' }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['status']['code']).to eq(401)
        expect(json_response['status']['message']).to eq(Messages::INVALID_AUTHENTICATION_TOKEN)
      end
    end
  end

  describe 'POST #google_sign_in' do
    let(:google_token) { 'valid_google_token' }

    before do
      allow(controller).to receive(:get_google_user_info).and_return(google_user_info)
    end

    context 'with existing Google user' do
      let!(:google_user) { create(:user, email: google_user_info['email'], provider: 'google', password: 'password', password_confirmation: 'password', confirmed_at: Time.now) }
      it 'returns a success response' do
        post :google_sign_in, params: { token: google_token }
        expect(response).to have_http_status(:ok)
        expect(json_response['status']['code']).to eq(200)
        expect(json_response['data']['user']['email']).to eq(google_user.email)
      end
    end

    context 'with new Google user' do
      it 'creates a new user and returns a success response' do
        post :google_sign_in, params: { token: google_token }
        expect(response).to have_http_status(:created)
        expect(json_response['status']['code']).to eq(201)
        expect(json_response['data']['user']['email']).to eq(google_user_info['email'])
      end
    end

    context 'with existing email registered with email provider' do
      let!(:existing_user) { create(:user, email: google_user_info['email'], password: 'password', password_confirmation: 'password', confirmed_at: Time.now) }

      it 'returns an unauthorized response' do
        post :google_sign_in, params: { token: google_token }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['status']['code']).to eq(401)
        expect(json_response['status']['message']).to eq(Messages::GOOGLE_AUTHENTICATION_FAILED)
        expect(json_response['status']['error']).to eq(Messages::USER_ALREADY_REGISTERED_WITH_EMAIL.call(existing_user.email))
      end
    end
  end
end
