# frozen_string_literal: true

class UsersController < InertiaController
  def new
    redirect_to "/dashboard" if Current.user
  end
end
