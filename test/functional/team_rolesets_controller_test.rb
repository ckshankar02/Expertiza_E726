require 'test_helper'

class TeamRolesetsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:team_rolesets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create team_roleset" do
    assert_difference('TeamRoleset.count') do
      post :create, :team_roleset => { }
    end

    assert_redirected_to team_roleset_path(assigns(:team_roleset))
  end

  test "should show team_roleset" do
    get :show, :id => team_rolesets(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => team_rolesets(:one).to_param
    assert_response :success
  end

  test "should update team_roleset" do
    put :update, :id => team_rolesets(:one).to_param, :team_roleset => { }
    assert_redirected_to team_roleset_path(assigns(:team_roleset))
  end

  test "should destroy team_roleset" do
    assert_difference('TeamRoleset.count', -1) do
      delete :destroy, :id => team_rolesets(:one).to_param
    end

    assert_redirected_to team_rolesets_path
  end
end
