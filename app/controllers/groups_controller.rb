class GroupsController < ApplicationController
  before_filter :block_information, :only => [:index, :show]
  before_filter :require_admin, :except => [:index, :show]
  before_filter :init_controller

  def index
  end

  def show
    render :layout => false
  end

  def new
  end

  def edit
  end

  def create
  if params[:parent_group].blank?
    @group.parent_group_id = ""
  else
    @group.parent_group_id = params[:parent_group][:name]
  end
    @group.name = @group.name.strip
    if @group.save
       redirect_back_or_default
    else
      render :action => "new"
    end
  end

  def update
      if @group.update_attributes(params[:group])
         redirect_back_or_default
      else
        render :action => "edit"
      end
  end

  def destroy
    Group.transaction do
      @group.move_group_products_to_parent_group
      @group.destroy
    end
     redirect_back_or_default
  end

  private
    def init_controller
      case action_name.to_sym
        when :index
          @groups = Group.order('created_at')
        when :new, :create
          @group = Group.new(params[:group])
        when :show, :edit, :update, :destroy
          @group = Group.find(params[:id])
      end
      case action_name.to_sym
        when :new,:create, :edit,:update
          @parent_groups = [""].concat(Group.all.collect{|g| [g.name, g.id] if g.name != @group.name}).compact
      end
    end
end