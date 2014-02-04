class CommentsController < ApplicationController

  def index
    @comments = Comment.all
  end

  def show
    @comment = Comment.find(params[:id])
  end

  def new
    @product = Product.find(params[:product_id])
    @comment = @product.comments.build(:parent_id => params[:parent_id])
  end

  def edit
    @comment = Comment.find(params[:id])
  end

  def create
    @product = Product.find(params[:product_id])
    @comment = @product.comments.build(params[:comment])
    if @comment.save
      redirect_to(product_path(@product), :notice => 'Comment was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    @comment = Comment.find(params[:id])
    if @comment.update_attributes(params[:comment])
      redirect_to(@comment, :notice => 'Comment was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy

    redirect_to(comments_url)
  end
end
