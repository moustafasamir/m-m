class StoresController < ApplicationController

  before_filter :reset_current_store
  before_filter :find_store, except: [:index, :new, :create, :storefronts]
  before_filter :authenticate_user!, except: [:index, :show, :storefronts]
  before_filter :authenticate_owner, except: [:index, :new, :create, :show, :storefronts]
  before_filter :set_edit_redirect_url, :only => :edit

  def index
    @stores = Store.order("name asc")
  end

  def show
    respond_with @store
  end

  def new
    @store = Store.new
  end

  def create
    @store = Store.new(params[:store])
    respond_to do |format|
      if @store.save
        format.html {redirect_to store_path(@store)}
      else                  
        format.html { render action: "new"}        
      end
    end    
  end

  def edit
  end

  def update 
    # we here have to responce for Ajax or Html.
    respond_to do |format|
      if @store.update_attributes(params[:store])
        format.html { redirect_to session[:edit_redirect_url]}
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @store.errors}
      end
    end    
  end

  def destroy
    @store.destroy
    session[:edit_redirect_url] = community_path(@store.community) if store_url(@store.id) == session[:edit_redirect_url]
    respond_to do |format|
      format.html { redirect_to session[:edit_redirect_url]}
    end
  end
  
  protected
  def find_store
    @store = Store.find(params[:id])

    # If an old id or a numeric id was used to find the record, then
    # the request path will not match the store_path, and we should do
    # a 301 redirect that uses the current friendly id.
    # if request.path != store_path(@store)
    #   return redirect_to @store, status: :moved_permanently
    # end
  end

  def authenticate_owner
    redirect_to @store unless @store.user == current_user || current_user.admin
  end

  def set_edit_redirect_url
    session[:edit_redirect_url] = request.referer.split("?")[0]
  end

  def reset_current_store
    cookies[:current_store_id] = nil
  end

end
