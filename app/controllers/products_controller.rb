class ProductsController < ApplicationController

  def index
    @products = Product.all.includes(:product_images).limit(4)
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product= Product.new
    @product.product_images.new

  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to root_url
    else
      render "new"
    end
  end

  def edit
  end

  def update
  end
  
  def destroy
  end

  def buy
  end

  private
  def product_params
    params.require(:product).permit(:name,
                                    :description, 
                                    :price, 
                                    :status, 
                                    :shipping_expenses, 
                                    :send_from, 
                                    :lead_time,
                                    :category_id,
                                    :order,
                                    product_images_attributes: [:image])
  end
end
