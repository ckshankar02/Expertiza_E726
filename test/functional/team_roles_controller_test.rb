require 'test_helper'

class TeamRolesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:team_roles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create team_role" do
    assert_difference('TeamRole.count') do
      post :create, :team_role => { }
    end

    assert_redirected_to team_role_path(assigns(:team_role))
  end

  test "should show team_role" do
    get :show, :id => team_roles(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => team_roles(:one).to_param
    assert_response :success
  end

  test "should update team_role" do
    put :update, :id => team_roles(:one).to_param, :team_role => { }
    assert_redirected_to team_role_path(assigns(:team_role))
  end

  test "should destroy team_role" do
    assert_difference('TeamRole.count', -1) do
      delete :destroy, :id => team_roles(:one).to_param
    end

    assert_redirected_to team_roles_path
  end
end
