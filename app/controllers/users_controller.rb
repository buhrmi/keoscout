# frozen_string_literal: true

class UsersController < InertiaController
  def new
    @scout = User.find_by(id: cookies[:scout_id]).as_json(only: [ :name ]) if cookies[:scout_id]
  end
end
