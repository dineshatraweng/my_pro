class UserGroupsController < ApplicationController
  before_filter  :require_admin
  def index
    @user_groups = UserGroup.all
  end

  def show
    @user_group = UserGroup.find(params[:id])
  end

  def new
    @user_group = UserGroup.new
  end

  def create
    @user_group = UserGroup.new(params[:user_group])
    if @user_group.save
      redirect_to user_groups_path
    else
      render "new"
    end
  end

  def edit
    @user_group = UserGroup.find(params[:id])
  end

  def update
    @user_group = UserGroup.find(params[:id])
    if @user_group.update_attributes(params[:user_group])
      redirect_to user_groups_path
    else
      render "edit"
    end
  end

  def destroy
    @user_group = UserGroup.find(params[:id])
    @user_group.destroy
  end

end

