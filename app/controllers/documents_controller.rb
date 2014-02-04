class DocumentsController < ApplicationController
  before_filter :block_information, :only => [:index, :show]
  before_filter :require_admin, :except => [:index, :show]

  def index
    @product = Product.find(params[:product_id])
    @documents = @product.documents
  end

  def show
    @document = Document.find(params[:id])
  end

  def new
    @product = Product.find(params[:product_id])
    @document = @product.documents.build(params[:document])
  end

  def edit
    @document = Document.find(params[:id])
    @product = @document.product
  end

  def create
    @product = Product.find(params[:product_id])
    @document = @product.documents.build(params[:document])
    if @document.save
      @document.update_count
      #@product.create_document_archive
      #redirect_back_or_default
      redirect_to product_path(@product)
    else
      render :action => "new"
    end
  end
  #
  #def update_page_count
  #  @product = Product.find(params[:product_id])
  #  @document = @product.documents.find(params[:id])
  #  @document.update_count
  #  render :action => "edit"
  #end

  def update
    @product = Product.find(params[:product_id])
    @document = Document.find(params[:id])
    if @document.update_attributes(params[:document])
      if @document.instance_variable_get(:@previously_changed).has_key?'link'
        @document.update_count
        #@product.create_document_archive
      end
      redirect_back_or_default
    else
      render :action => "edit"
    end
  end

  def destroy
    @document = Document.find(params[:id])
    @product = @document.product
    @document.destroy
    #@product.create_document_archive
    #session[:product_id] = @document.product.id
    redirect_to(product_path(@product))
  end

  def document_order
    params[:document].each_with_index do |doc_id,index|
      doc = Document.find(doc_id.to_i)
      doc.update_attribute(:document_order , index+1)
      #doc.update_attributes(:document_order => index+1)
    end
    render :nothing => true
  end

  def out_of_cycle
    @document = Document.find(params[:id])
    @document.out_of_cycle = DateTime.now
    @document.save
    redirect_to(product_path(params[:product_id]))
  end
end