# frozen_string_literal: true

class UsersController < InertiaController
  def new
    @referrer = User.find_by(id: session[:scout_id]).as_json(only: [ :name ]) if session[:scout_id]
  end
end
