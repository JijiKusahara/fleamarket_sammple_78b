class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :move_to_index, except: [:index, :show, :new]
  before_action :set_card, only: [:buy, :pay]

  def index
    @products = Product.all.includes(:product_images).order("RAND()").limit(4)
  end

  def show
    @product= Product.find(params[:id])
    @parents = Category.where(ancestry:nil)
  end
  
  def new
    if user_signed_in?
      @product = Product.new
      @product.product_images.new
    else
      redirect_to new_user_session_path
    end
  end

  def create
    @product = Product.new(product_params)
    @product.save
    if @product.save
      redirect_to root_url
    else
      @product.product_images.new
      render :new
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to root_path
    else
      @product.product_images = Product.find(params[:id]).product_images
      render "edit"
    end
  end

  def destroy
    if @product.user_id == current_user.id && @product.destroy
      flash[:notice] = "削除が完了しました。"
      redirect_to root_url
    else
      flash[:alert] = "削除できませんでした。"
      redirect_to root_url
    end
  end

  def search_child
    respond_to do |format|
      format.html
      format.json do
        @children = Category.find(params[:parent_id]).children
      end
    end
  end

  def search_grandchild
    respond_to do |format|
      format.html
      format.json do
        @grandchildren = Category.find(params[:child_id]).children
      end
    end
  end

  require 'payjp'

  def buy
    #Cardテーブルは前回記事で作成、テーブルからpayjpの顧客IDを検索
    @product = Product.find(params[:id])
    if @card.nil?
      #登録された情報がない場合にカード登録画面に移動
      redirect_to user_path(current_user.id)
      flash[:alert] = "カードが登録されていません。"
    elsif @product.order == "購入済"
      redirect_to root_path
      flash[:alert] = "購入済みです。"
    else
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      #保管した顧客IDでpayjpから情報取得
      customer = Payjp::Customer.retrieve(@card.customer_id)
      #保管したカードIDでpayjpから情報取得、カード情報表示のためインスタンス変数に代入
      @default_card_information = customer.cards.retrieve(@card.card_id)
    end
  end

  def pay
    Payjp.api_key = ENV['PAYJP_PRIVATE_KEY']
    Payjp::Charge.create(
    amount: Product.find(params[:id]).price, #支払金額を入力（itemテーブル等に紐づけても良い）
    customer: @card.customer_id, #顧客ID
    currency: 'jpy', #日本円
  )
  redirect_to action: 'done' #完了画面に移動
  end

  def done
    @product = Product.find(params[:id])
    @product.order = "購入済"
    @product.buyer_id = current_user.id
    @product.save
    @product.update( buyer_id: current_user.id)
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
                                    product_images_attributes: [:image, :_destroy, :id])
                             .merge(user_id: current_user.id, order: "出品中")
  end

  def set_product
    @product = Product.find(params[:id])
  end

  def move_to_index
    redirect_to action: :index unless user_signed_in?
  end
  def set_card
    @card = CreditCard.where(user_id: current_user.id).first
  end
end
