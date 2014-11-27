class ProductsController < ApplicationController
  load_and_authorize_resource

  before_filter :find_product, only: [:show, :edit, :update, :destroy]
  before_filter :find_store, only: [:index, :new, :create]  
  before_filter :set_edit_redirect_url, :only => :edit
  # before_filter :authenticate_owner, except: [:index, :show, :list, :random, :nearby, :gifts, :items, :storefronts]

  #list product is for the users
  def list
    @products = Product.order("name asc")
  end
  
  #index product is for the store admin
  def index    
    @products = Product.order("name asc")  
  end

  def show
    respond_with @product
  end

  def new
    @product = Product.new
  end

   def create
    @product = Product.new(params[:product])    
    @product.user = current_user
    respond_to do |format|
      if @product.save
        format.html {
          render :json => [@product.to_jq_upload].to_json,
          :content_type => 'text/html',
          :layout => false
        }
        format.json { render json: [@product.to_jq_upload].to_json, status: :created, location: @upload }
      else
        format.html { render action: "new" }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit        
  end

  def update 
    # we here have to responce for Ajax or Html.
    respond_to do |format|
      if @product.update_attributes(params[:product])
        format.html {redirect_to session[:edit_redirect_url]}
        format.json { head :ok }
      else
        format.html { render action: "edit"}
        format.json { render json: @product.errors}
      end
    end    
  end

  def destroy
    @product.destroy
    session[:edit_redirect_url] = @product.store ? store_path(@product.store) : user_path(current_user) if product_url(@product.id) == session[:edit_redirect_url]

    respond_to do |format|
      format.html { redirect_to session[:edit_redirect_url]}
    end
  end

  def likes
    user = User.find(params[:user_id])
    @products = user.liked_products
  end
  
  protected
  def find_store
    @store = Store.find_by_id(params[:store_id])
    redirect_to root_path and return unless @store
  end

  def find_product
    @product = Product.find_by_id(params[:id])
    redirect_to root_path and return unless @product
  end

  def authenticate_owner
    redirect_to @store if @store.user != current_user
  end

  def set_edit_redirect_url
    session[:edit_redirect_url] = request.referer
  end
end
