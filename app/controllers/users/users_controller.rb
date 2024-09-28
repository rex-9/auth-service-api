class Users::UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :get_current_user ]

  # GET /users/current
  def get_current_user
    render_json_response(
      status_code: 200,
      message: "Current user fetched successfully.",
      data: { user: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
    )
  end
end
