# frozen_string_literal: true

class UsersController < InertiaController
  def index
    redirect_to "/dashboard" if Current.user
  end

  def new
  end

  def create
    user = User.create!(create_params)
    session[:user_id] = user.id
    redirect_to dashboard_root_path, notice: "Account created successfully."
  end

  private
  def create_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
