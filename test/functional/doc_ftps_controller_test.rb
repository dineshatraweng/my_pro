require 'test_helper'

class DocFtpsControllerTest < ActionController::TestCase
  setup do
    @doc_ftp = doc_ftps(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:doc_ftps)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create doc_ftp" do
    assert_difference('DocFtp.count') do
      post :create, :doc_ftp => @doc_ftp.attributes
    end

    assert_redirected_to doc_ftp_path(assigns(:doc_ftp))
  end

  test "should show doc_ftp" do
    get :show, :id => @doc_ftp.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @doc_ftp.to_param
    assert_response :success
  end

  test "should update doc_ftp" do
    put :update, :id => @doc_ftp.to_param, :doc_ftp => @doc_ftp.attributes
    assert_redirected_to doc_ftp_path(assigns(:doc_ftp))
  end

  test "should destroy doc_ftp" do
    assert_difference('DocFtp.count', -1) do
      delete :destroy, :id => @doc_ftp.to_param
    end

    assert_redirected_to doc_ftps_path
  end
end
