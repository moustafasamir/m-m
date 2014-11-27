class Api::V1::ProductsController < Api::V1::BaseController
  before_filter :authenticate_api_user!, only: [:create, :update, :destroy, :pending, :approve, :deny, :rate, :user_local]
  load_and_authorize_resource
  paginate :search, only: [:search, :nearby], type: :sunspot
  paginate :products, only: [:index, :likes], type: :will_paginate
  before_filter :set_tag_list, :only=>[:create, :update]
  after_filter :set_pages_headers, :only=>[:index, :latest, :random, :featured, :popular, :items_added, :categorized]
  before_filter :load_user_community,:only => [:latest, :popular, :random], :if => "params[:consider_location]"
  # =begin apidoc
  # url:: GET - /api/v1/stores/:store_id/products
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of products for specific store.
  # param:: store_id:int - The store ID [Rest]
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination 
  # param:: precision:int - for Pagination 
  # Header:: 'X-Pagination': '"{\"total\":2,\"total_pages\":1,\"first_page\":true,\"last_page\":true,\"previous_page\":null,\"next_page\":null,\"out_of_bounds\":false,\"offset\":0}"'
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "rate": "3",
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of all Products in store with pagination.  Defaults to 10 per page
  # =end  

  # =begin apidoc
  # url:: GET - /api/v1/users/:user_id/products
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of products for specific user.
  # param:: user_id:int - User ID [Rest]
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination 
  # param:: precision:int - for Pagination 
  # Header:: 'X-Pagination': '"{\"total\":2,\"total_pages\":1,\"first_page\":true,\"last_page\":true,\"previous_page\":null,\"next_page\":null,\"out_of_bounds\":false,\"offset\":0}"'
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of all Products for User with pagination.  Defaults to 10 per page
  # =end  

  # =begin apidoc  
  # url:: GET - /api/v1/categories/:category_id/products
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of products in category.
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination     
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of Products in specific category.
  # =end    

  def index
    parent = nil
    @products = if params[:store_id]
      store = Store.find(params[:store_id])
      store.products.paginate(pagination_options)
    elsif params[:user_id]
      user = User.find(params[:user_id])
      user.products.paginate(pagination_options)
    elsif params[:community_id]
      community = Community.find(params[:community_id])
      Product.in_community(community)
    elsif params[:category_id]
      options=pagination_options.deep_merge({:category=>params[:category_id]}).deep_merge(params)
      Product.search(options).results
    else
      Product.search(params).results
    end
    #location will be passed in the parameters
    # if params[:location] || (params[:lat] && params[:lng])
    #   @products = order_by_location(@products, params)
    # end
    respond_with @products
  end

  # =begin apidoc
  # url:: GET - /api/v1/products/latest
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of latest products added.  
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of latest Products added in the system
  # =end  

  # =begin apidoc
  # url:: GET - /api/v1/stores/:store_id/products/latest
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of latest products for specific store.  
  # param:: store_id:integer - Store ID
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # param:: options[per_page]:integer -- for pagination default is 20
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of latest products for specific store.
  # =end  

  # =begin apidoc
  # url:: GET - /api/v1/communities/:community_id/products/latest
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of latest products for specific community.  
  # param:: community_id:integer - Community ID
  # param:: price_range:integer -- IF you want the product in price range send here the top range price EX. if range 0$-50$ send 50
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # param:: options[per_page]:integer -- for pagination default is 20
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of latest products for specific community.
  # =end  

  def latest
    params[:search] ||= {}
    store_id = params[:store_id] || cookies[:current_store_id]
    store = Store.find(store_id) if store_id.present?
    @products = if params[:store_id]
      cookies[:current_store_id] = store_id
      store.products.latest(24).paginate(pagination_options)
    elsif params[:realtime]
      #loading products from database not from solr when getting latest products to allow products to appear immediately after adding creating them(this was a mobile issue)
      Community.where("city ilike ? and state ilike ?", params[:city], params[:state]).first.try{|c|c.products.latest.paginate(pagination_options)}
    elsif cookies[:community_id]
      if cookies[:current_store_id].present?
        store.products.price_range(params[:price_range]).latest(24).paginate(pagination_options)
      else
        Community.where(["id = ?",cookies[:community_id]]).first.products.price_range(params[:price_range]).latest(24).paginate(pagination_options)
      end
    else
      Product.search(params.merge({latest: true, community_id: cookies[:community_id]})).results
    end
    #this is a work around as sometimes solr crash on production and doesn't return any result, until we know why this issue happens.
    Product.first.try("delay").try("check_reindex") if @products.blank?
    respond_with @products
  end

  # =begin apidoc
  # url:: GET - /api/v1/products/popular
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of popular products.  
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of popular Products which is the most liked.
  # =end  

  # =begin apidoc
  # url:: GET - /api/v1/stores/:store_id/products/popular
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of popular products for specific store.  
  # param:: store_id:integer - Store ID
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # param:: options[per_page]:integer -- for pagination default is 20
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of popular products for specific store.
  # =end  

  # =begin apidoc
  # url:: GET - /api/v1/communities/:community_id/products/popular
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of popular products for specific community.  
  # param:: community_id:integer - Community ID
  # param:: price_range:integer -- IF you want the product in price range send here the top range price EX. if range 0$-50$ send 50
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # param:: options[per_page]:integer -- for pagination default is 20
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of popular products for specific community.
  # =end  

  # def popular2
  #   params[:search] ||= {}
  #   if params[:store_id]
  #     store = Store.find(params[:store_id])
  #     @products = store.products.popular.paginate(pagination_options)
  #   elsif params[:community_id]
  #     community = Community.find(params[:community_id])
  #     @products = Product.popular.in_community(community).price_range(params[:price_range] || 0).paginate(pagination_options)
  #   end
  #   @products = Product.popular.price_range(params[:price_range] || 0).paginate(pagination_options) unless @products
  #   #location will be passed in the parameters
  #   if params[:location] || (params[:lat] && params[:lng])
  #     @products = order_by_location(@products, params)
  #   end
  #   respond_with @products
  # end

  def popular
    params[:search] ||= {}
    @products = if params[:store_id]
      store = Store.find(params[:store_id])      
      store.products.popular.paginate(pagination_options)
    elsif params[:community_id]
      community = Community.find(params[:community_id])
      Product.popular.in_community(community).price_range(params[:price_range] || 0).paginate(pagination_options)
    # elsif params[:price_range]
    #   products = Product.popular.price_range(params[:price_range] || 0).paginate(pagination_options)
    #   #location will be passed in the parameters
    #   if params[:location] || (params[:lat] && params[:lng])
    #     products = order_by_location(products, params)
    #   end
    #   products
    else
      Product.search(params.merge({popular: true})).results
    end
    respond_with @products
  end




  # =begin apidoc
  # url:: GET - /api/v1/products/featured
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of featured products.  
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #    rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of featured Products.
  # =end  

  # =begin apidoc
  # url:: GET - /api/v1/stores/:store_id/products/featured
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of featured products for specific store.  
  # param:: store_id:integer - Store ID
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination     
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of featured products for specific store.
  # =end  

  # =begin apidoc
  # url:: GET - /api/v1/communities/:community_id/products/featured
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of featured products for specific community.  
  # param:: community_id:integer - Community ID
  # param:: price_range:integer -- IF you want the product in price range send here the top range price EX. if range 0$-50$ send 50
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of featured products for specific community.
  # =end 
  def featured
    params[:search] ||= {} 
    if params[:store_id]
      store = Store.find(params[:store_id])
      @products = store.products.featured.paginate(pagination_options)
    elsif params[:community_id]
      community = Community.find(params[:community_id])
      @products = Product.featured.in_community(community).price_range(params[:price_range] || 0).paginate(pagination_options)
    end
    @products = Product.featured.price_range(params[:price_range] || 0).paginate(pagination_options) unless @products
    #location will be passed in the parameters
    if params[:location] || (params[:lat] && params[:lng])
      @products = order_by_location(@products, params)
    end
    respond_with @products
  end

  # =begin apidoc
  # url:: GET - /api/v1/products/random
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of random products.  
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of random products.
  # =end  

  # =begin apidoc
  # url:: GET - /api/v1/stores/:store_id/products/random
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of random products for specific store.  
  # param:: store_id:integer - Store ID
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of random products for specific store.
  # =end  

  # =begin apidoc
  # url:: GET - /api/v1/communities/:community_id/products/random
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of random products for specific community.  
  # param:: community_id:integer - Community ID
  # param:: price_range:integer -- IF you want the product in price range send here the top range price EX. if range 0$-50$ send 50
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination   
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of random products for specific community.
  # =end  

  def random
    params[:search] ||= {}
    # params[:search][:paginate] = false
    @products = if params[:store_id]
      store = Store.find(params[:store_id])      
      store.products.order("RANDOM()").paginate(pagination_options)
    elsif params[:community_id]
      community = Community.find(params[:community_id])
      Product.order("RANDOM()").in_community(community).price_range(params[:price_range] || 0).paginate(pagination_options)
    else
      Product.search(params.merge({random: true})).results
    end
    respond_with @products
  end


  def categorized
    @products = []
    category = Category.find_by_name(params[:category])
    if category
      options = pagination_options.deep_merge({:category=>category.id})
      #add parameters
      options[:community_id] = cookies[:community_id] if cookies[:community_id]
      options[:featured] = true if params[:filter] == "featured"
      options[:latest] = true if params[:filter] == "latest"
      options[:popular] = true if params[:filter] == "popular"
      options[:random] = true if params[:filter] == "random"
      @products = Product.search(options).results
    end
    respond_with @products
  end

  # =begin apidoc
  # url:: GET - /api/v1/products/search
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of products meet serach terms.
  # param:: keywords:string - keywords=blue (Ex)  
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of products meet serach terms.
  # =end  
  def search
    params.merge!({"community_id" => cookies[:community_id]}) if cookies[:community_id] 
    @search = Product.search(params.symbolize_keys)
    @products = @search.results
    respond_with @products
  end

  # =begin apidoc
  # url:: GET - /api/v1/products/nearby
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of nearby products and meet serach terms.
  # param:: keywords:string - keywords=blue (Ex)
  # param:: lat:string
  # param:: lng:string
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of nearby products and meet serach terms.
  # =end  
  def nearby
    params[:lat] ||= current_user.try(:lat)
    params[:lng] ||= current_user.try(:lng)
    @search = Product.search(params.symbolize_keys)
    @products = @search.results
    respond_with @products
  end
  
  # =begin apidoc
  # url:: GET - /api/v1/stores/:store_id/products/pending
  # method:: GET
  # access:: Registered User [Verified Store Owner]
  # return:: [JSON] - Products
  # param:: store_id:int - Store ID  
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of pending products waiting approval to be approved by store owner in case of featured store.
  # =end  
  def pending
    store = Store.find(params[:store_id])
    if current_user == store.owner && store.featured
      @products = store.products.unscoped.hidden
    else
      unauthorized_access and return  
    end
    respond_with @products
  end


  # =begin apidoc
  # url:: POST - /api/v1/products/:id/approve
  # method:: POST
  # access:: Registered User [Verified Store Owner]
  # return:: [JSON] - Product
  # param:: id:int - Product ID  
  # output:: json
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   } 
  # ::output-end::
  #
  # Approve product to be added to store, as it was hidden until store owner approval.
  # =end  
  def approve
    @product.state = :active
    @product.save
    respond_with @product
  end

  # =begin apidoc
  # url:: POST - /api/v1/products/:id/deny
  # method:: POST
  # access:: Registered User [Verified Store Owner]
  # return:: [JSON] - Product
  # param:: id:int - Product ID  
  # output:: json
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   } 
  # ::output-end::
  #
  # Deny product to not be added to store.
  # =end  
  def deny
    @product.state = :hidden
    @product.save
    respond_with @product
  end

  # =begin apidoc
  # url:: GET - /api/v1/users/:user_id/products/likes
  # method:: GET
  # access:: FREE
  # return:: [JSON] - list of products user like.
  # param:: user_id:int - User ID [Rest]
  # param:: page:int - the page, default is 1  - for Pagination 
  # param:: per_page:int - max items per page, default is 10 - for Pagination 
  # param:: precision:int - for Pagination 
  # Header:: 'X-Pagination': '"{\"total\":2,\"total_pages\":1,\"first_page\":true,\"last_page\":true,\"previous_page\":null,\"next_page\":null,\"out_of_bounds\":false,\"offset\":0}"'
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  },
  #   {  id: 151,
  #        .....
  #   }
  # ]
  # ::output-end::
  #
  # Get a list of Products user like with pagination.  Defaults to 10 per page
  # =end  
  def likes
    user = User.find(params[:user_id])
    @products = user.liked_products.latest.paginate(pagination_options)
    respond_with @products
  end

  # =begin apidoc
  # url:: GET - /api/v1/products/:id (200)
  # method:: GET
  # access:: FREE
  # return:: [JSON] - Product.
  # param:: id:int - Product ID [Rest]
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "rate": "3",
  #   "tag_list": [
  #
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  }
  # ]
  # ::output-end::
  #
  # Show a product details.
  # =end  
  
  # =begin apidoc
  # url:: GET - /api/v1/products/:id (404)
  # method:: GET
  # access:: FREE
  # return:: [JSON] - Failure message as id not provided or wrong ID.
  # param:: id:int - Product ID [Rest]
  # output:: json
  # {
  #   "message": "Couldn't find Product with id=0" 
  # }
  # ::output-end::
  #
  # Failed to show a product details as wrong ID given.
  # =end  
  def show
    respond_with @product
  end

  # =begin apidoc
  # url:: POST - /api/v1/products/:id/rate
  # method:: POST
  # access:: Require User
  # return:: [JSON] - Average Rate.
  # param:: rate=integer - Rate between 1 - 5
  # output:: json
  # {
  #   "rate":3.5
  # }
  # ::output-end::
  #
  # Rate a product and return the average for all raters
  # =end  
  def rate
    if params[:rate] && is_numeric?(params[:rate]) && params[:rate].to_i <= 5
      rate = @product.rated_by?(current_user)
      rate.destroy if rate
      @product.rate_it(params[:rate], current_user)
    end
    respond_with @product
  end
  # =begin apidoc
  # url:: POST - /api/v1/products(200)
  # method:: POST
  # access:: Registered User
  # return:: [JSON] - Cerated Product.
  # param:: product[description]:String
  # param:: product[name]=String
  # param:: product[store_name]=String
  # param:: product[price]=Number
  # param:: product[category]=CategoryName
  # param:: product[tag_list]="Nice, Good, Expensive, Accessories"
  # param::product[image]=image file
  # param:: .....
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  }
  # ]
  # ::output-end::
  #
  # Cerate a Product and return the created Product.
  # =end  


  # =begin apidoc
  # url:: POST - /api/v1/products(401)
  # method:: POST
  # access:: Registered User
  # return:: [JSON] - Failure message as no user found.
  # param:: product[description]:String
  # param:: product[name]=String
  # param:: product[store_name]=String
  # param:: product[price]=Number
  # param:: product[category]=CategoryName
  # param:: product[tag_list]="Nice, Good, Expensive, Accessories"
  # param::product[image]=image file
  # param:: .....
  # output:: json
  #  {
  #    "message": "You must be an authenticated user to access this API!" 
  #  }
  # ::output-end::
  #
  # Fail to cerate a Product and return failure message as no user found.
  # =end  

  # =begin apidoc
  # url:: POST - /api/v1/products (422)
  # method:: POST
  # access:: Registered User
  # return:: [JSON] - Errors as Validation Failed.
  # param:: product[description]=String
  # param:: product[name]=String
  # param:: product[store_name]=String
  # param:: product[price]=Number
  # param:: product[category]=CategoryName  
  # param:: product[tag_list]="Nice, Good, Expensive, Accessories"  
  # param::product[image]=image file
  # param:: .....
  # param:: Request Body  Image  Encoded Base64 without key
  # output:: json
  # {
  #   "errors": {
  #     "price": [
  #       "must be greater than or equal to 0.0"
  #     ]
  #   }
  # }
  # ::output-end::
  #
  # Fail to cerate a Product validation failed.
  # =end  

  def create
    @product = Product.new(params[:product])    
    @product.user = current_user
    @product.save
    respond_with @product
  end
  
  # def old_create
  #   params[:image] ||= request.body.read
  #   @product = Product.new(params[:product])
  #   @product.user = current_user
  #   if @product.save
  #     begin
  #       if params[:image] && params[:image_name]
  #         @product.image_from_base64 params[:image], params[:image_name]
  #         @product.save 
  #       end            
  #     rescue
  #     end  
  #   end    
  #   respond_with @product
  # end

  # =begin apidoc  
  # url:: PUT - /api/v1/products/:id(200)
  # method:: PUT
  # access:: Registered User
  # return:: [JSON] - Updated Product.
  # param:: id:int -  Product ID [Rest]
  # param:: product[description]:String
  # param:: product[name]=String
  # param:: product[store_name]=String
  # param:: product[price]=Number
  # param:: product[category]=CategoryName
  # param:: product[tag_list]="Nice, Good, Expensive, Accessories"  
  # param:: image_name=string - image name with extension  
  # param:: Request Body  Image  Encoded Base64 without key
  # param:: .....
  # output:: json
  # [
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #   rate: 3,  
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  }
  # ]
  # ::output-end::
  #
  # Update a Product and return the Updated one.
  # =end  


  # =begin apidoc
  # url:: PUT - /api/v1/products/:id(401)
  # method:: PUT
  # access:: Registered User
  # return:: [JSON] - Failure message as no user found.
  # param:: product[description]:String
  # param:: product[name]=String
  # param:: product[store_name]=String
  # param:: product[price]=Number
  # param:: product[category]=CategoryName
  # param:: product[tag_list]="Nice, Good, Expensive, Accessories"
  # param:: image=string - Encoded Base64
  # param:: image_name=string - image name with extension    
  # param:: .....
  # output:: json
  #  {
  #    "message": "You must be an authenticated user to access this API!" 
  #  }
  # ::output-end::
  #
  # Fail to Update a Product info and return failure message as no user found.
  # =end  

  # =begin apidoc
  # url:: PUT - /api/v1/products/:id (422)
  # method:: PUT
  # access:: Registered User
  # return:: [JSON] - Errors as Validation Failed.
  # param:: product[description]:String
  # param:: product[name]=String
  # param:: product[store_name]=String
  # param:: product[price]=Number
  # param:: product[category]=CategoryName
  # param:: product[tag_list]="Nice, Good, Expensive, Accessories"
  # param:: image=string - Encoded Base64
  # param:: image_name=string - image name with extension  
  # param:: .....
  # Body:: product[price]=-1.0
  # output:: json
  # {
  #   "errors": {
  #     "price": [
  #       "must be greater than or equal to 0.0"
  #     ]
  #   }
  # }
  # ::output-end::
  #
  # Fail to Update a Product validation failed.
  # =end  

  def update    
    params[:image] ||= request.body.read
    @product.update_attributes(params[:product])
    begin
      if params[:image] && params[:image_name]
        @product.image_from_base64 params[:image], params[:image_name]
        @product.save 
      end
    rescue
    end      
    respond_with @product
  end

  # =begin apidoc
  # url:: DELETE - /api/v1/products/:id
  # method:: DELETE
  # access:: Registered User
  # return:: [JSON] - Deleted Product.
  # param:: id:int - Product ID  - [Rest]
  # output:: json
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  }
  # ::output-end::
  #
  # Destroy a Product and return it.
  # =end  

  def destroy
    @product.destroy
    respond_with @product
  end

  # =begin apidoc
  # url:: GET - /api/v1/products/near_location
  # method:: GET
  # access:: Public
  # return:: [JSON] - Products
  # param:: location: String - provide this location if not know lat and lng 
  # param:: lat: String 
  # param:: lng: String 
  # output:: json
  # {
  #   [
  #     {"id":15, "image_url":"/uploads/store/image/15/store.jpg"},
  #     {"id":29, "image_url":"/uploads/store/image/29/store.jpg"}
  #   ]
  # }
  # ::output-end::
  #
  # Get the products close to location by location name OR latitude and longitude
  # =end  
  def near_location
    params[:paginate] = false
    @products = Product.search(params).results
    respond_with @products
  end


  def user_local
    @products = current_user.my_local
    respond_with @products
  end

  # =begin apidoc
  # url:: GET - /api/v1/users/:user_id/products/items_added
  # method:: GET
  # access:: Free
  # return:: [JSON] - Products added by this user.
  # param:: user_id:int - User ID  - [Rest]
  # output:: json
  #  {
  #   "id": 25,
  #   "name": "Gucci Handbag",
  #   "description": "A fancy black handbag",
  #   "price": "100.0",
  #   "state": "active",
  #   "like_count": 0,
  #   "tag_list": [
  #   ],
  #   "user_id": 62,
  #   "store_id": 26,
  #   "created_at": "2012-08-02T02:56:18Z",
  #   "updated_at": "2012-08-02T02:56:18Z",
  #   "image": {
  #     "full": "Url goes here",
  #     "thumb": "Url goes here",
  #     "mid": "Url goes here",
  #     "big": "Url goes here"
  #   },
  #   like: false,        //Only in case User exict
  #      rate: 3,
  #   "permissions": {
  #     "manage": false,
  #     "read": true,
  #     "create": true,
  #     "update": false,
  #     "destroy": false
  #   }
  #  }
  # ::output-end::
  #
  # Get Products added by specific user.
  # =end   
  def items_added
    user = User.find(params[:user_id])
    @products = user.products.order("created_at desc").paginate(pagination_options)
    respond_with @products
  end

  def next_product    
    @product = Product.find_by_id(params[:id])
    @product = Product.next_latest(@product).first || Product.next_first(@product).first if @product
    @product||= Product.first
    respond_with @product
  end

  def previous_product
    @product = Product.find_by_id(params[:id])
    @product = Product.previous_latest(@product).first || Product.previous_last(@product).first  if @product
    @product||= Product.first
    respond_with @product
  end

  protected
  def set_tag_list
    if params[:product].present?
      params[:product][:tag_list] ||= params[:tag_list]
    end
  end

  def set_pages_headers
    if !@products.empty?
      headers["X-Pagination"] = {      
        next_page: true
      }.to_json
    else
      headers["X-Pagination"] = {
        last_page: true
      }.to_json
    end    
  end

  def load_user_community
    community = if cookies[:community_id]
      Community.find_by_id(cookies[:community_id])

    else
      cookies[:country].try :upcase!
      if cookies[:city] and cookies[:state] and cookies[:country] == 'US'
        #find this community
        Community.select("id, products_count").where(:city => cookies[:city].capitalize, :state => cookies[:state]).limit(1).first
      end
    end
    if community
      cookies[:community_id] = {
        :value => community.id,
        :expires => 1.days.from_now,
        :path => "/"
      }
      cookies[:city] = {
        :value => community.city,
        :expires => 1.days.from_now,
        :path => "/"
      }
      cookies[:state] = {
        :value => community.state_name,
        :expires => 1.days.from_now,
        :path => "/"
      }
      cookies[:country] = {
        :value => community.country,
        :expires => 1.days.from_now,
        :path => "/"
      }
      if community.products_count > 0
        params[:community_id] = community.id
        cookies[:community_products_empty] = {
          :value => false,
          :path => "/"
        }
      else
        cookies[:community_products_empty] = {
          :value => true,
          :path => "/"
        }
      end
    end
  end
end