class ParentGroupsController < ApplicationController
  before_filter :block_information
  before_filter :require_admin
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
    if @parent_group.save
      redirect_to(@parent_group, :notice => 'Parent group was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    if @parent_group.update_attributes(params[:parent_group])
      redirect_to(@parent_group, :notice => 'Parent group was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @parent_group.destroy
    redirect_to(parent_groups_url)
  end

  private
    def init_controller
      case action_name.to_sym
        when :index
          @parent_groups = ParentGroup.all
        when :new, :create
          @parent_group = ParentGroup.new(params[:parent_group])
        when :show, :edit, :update, :destroy
          @parent_group = ParentGroup.find(params[:id])
      end
    end
end