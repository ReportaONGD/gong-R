require 'test_helper'

class UserFlowsTest < ActionController::IntegrationTest
  fixtures :all

  def sign_up
    # test "usuario admin crea proyecto" do
    visit home_path
    fill_in "Usuario", :with => "admin"
    fill_in "Contraseña", :with => "admin"
    click_button "Enviar"
    assert_response :success
  end

end
