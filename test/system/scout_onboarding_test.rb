require "application_system_test_case"

class ScoutOnboardingTest < ApplicationSystemTestCase
  setup do
    @scout = User.create!(
      id: 1,
      email: "scout@example.com",
      name: "Scout",
      password: "password123"
    )

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:zalo] = OmniAuth::AuthHash.new(
      provider: "zalo",
      uid: "zalo-uid-123",
      info: {
        email: "talent@example.com",
        name: "New Talent",
        image: nil
      }
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:zalo] = nil
    OmniAuth.config.test_mode = false
    Rails.application.env_config["omniauth.auth"] = nil
  end

  test "new user keeps revenue share and scout id after zalo sign in" do
    visit root_path(scout_id: @scout.id)

    slider = find("input[type='range']", visible: :all)
    page.execute_script(
      "arguments[0].value = 30; arguments[0].dispatchEvent(new Event('input', { bubbles: true }));",
      slider.native
    )
    assert_text "30%"

    click_link "continue to dashboard"
    assert_current_path new_session_path, ignore_query: true
    assert_text(/(continue|log in) with zalo/i)


    click_on("Log in with Zalo")

    assert_text "Account Balance"

    user = User.where.not(id: @scout.id).order(:id).last
    assert_not_nil user
    assert_equal 30, user.share_percentage
    assert_equal @scout.id, user.scout_id
  end
end
