class RatingsController < ApplicationController

  def rate
    @product = Product.find(params[:product_id])
    @rating = @product.ratings.build(:rating => params[:rating])

    respond_to do |format|
      if @rating.save
        format.json {render :text => @product.avg_rating.to_s }
      else
        format.json {render :text => @rating.errors }
      end
    end
  end

end
