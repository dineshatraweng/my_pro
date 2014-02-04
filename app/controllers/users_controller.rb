class UsersController < ApplicationController
  before_filter :require_admin#, :except => [:index, :new, :create]
  before_filter :init_controller

  def index
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
    if @user.save
      redirect_to(products_path, :notice => 'User was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    if @user.update_attributes(params[:user])
      redirect_to(products_path, :notice => 'User was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    if @user.destroy
      redirect_to root_url
    else
      redirect_to(@user, :notice => ("Something went wrong!!!"))
    end
  end

private
  def init_controller
    case action_name.to_sym
      when :index, :new, :create
        @user = action_name.to_sym == :index ? User.all : User.new(params[:user])
      when :show, :edit, :update, :destroy
        @user = User.find(params[:id])
    end
  end
end