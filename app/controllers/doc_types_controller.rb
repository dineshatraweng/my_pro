class DocTypesController < ApplicationController
  before_filter :block_information, :only => [:index, :show]
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
    if @doc_type.save
      redirect_to(root_url, :notice => 'Doc type was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    if @doc_type.update_attributes(params[:doc_type])
      redirect_to(root_url, :notice => 'Doc type was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @doc_type.destroy
    redirect_to root_url
  end

  private
    def init_controller
      case action_name.to_sym
        when :index
          @doc_types = DocType.all
        when :new, :create
          @doc_type = DocType.new(params[:doc_type])
        when :show, :edit, :update, :destroy
          @doc_type = DocType.find(params[:id])
      end
    end
end