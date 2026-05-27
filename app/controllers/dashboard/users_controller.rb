class Dashboard::UsersController < Dashboard::BaseController
  def show
    render inertia: "dashboard/users/show"
  end
end
