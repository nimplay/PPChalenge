class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_admin!

  # GET /products
  def index
    @products = Product.includes(:categories, :creator).all
  end

  def show
  end

  def new
    @product = Product.new
  end

  def edit
  end

  # POST /products
  def create
    Current.user = current_user
    @product = current_user.created_products.new(product_params)

    if @product.save
      redirect_to @product, notice: "Product was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /products/1
  def update
    Current.user = current_user
    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /products/1
  def destroy
    @product.destroy
    redirect_to products_url, notice: "Product was successfully destroyed."
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :name,
        :description,
        :price,
        :stock,
        :product_type,
        category_ids: [],
        images: []
      )
    end

    def authorize_admin!
      unless current_user.admin?
        redirect_to root_path, alert: "You are not authorized to perform this action."
      end
    end
end
