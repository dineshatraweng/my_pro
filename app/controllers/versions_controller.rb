class VersionsController < ApplicationController
  before_filter :block_information
  before_filter :require_admin, :except => [:index]
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
    if @version.save
      redirect_to(product_version_path(@version.product,@version), :notice => 'Version was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    if @version.update_attributes(params[:version])
      redirect_to(product_version_path(@version.product,@version), :notice => 'Version was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @version.destroy
    redirect_to(product_versions_path(@product))
  end

private
  def init_controller
    exception = false
    begin
      @product = Product.find(params[:product_id])
      if @product.blank?
        exception = true
      else
        case action_name.to_sym
          when :index, :new, :create
            @version = action_name.to_sym == :index ? @product.versions : @product.versions.build(params[:version])
          when :show, :edit, :update, :destroy
            @version = @product.versions.find(params[:id])
        end
      end
    rescue
      exception = true
    end
    redirect_to root_path, :notice => "Product not found" if exception
  end
end