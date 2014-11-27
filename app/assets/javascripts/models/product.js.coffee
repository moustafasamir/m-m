class @MainAndMe.Models.Product extends MainAndMe.Models.BaseModel

  @priceRanges:
    25: "$0 - $25"
    50: "$25 - $50"
    100: "$50 - $100"
    200: "$100 - $200"
    500: "$200 - $500"
    1000: "$500 -$1000"
    10000: "$1000 and up"

  paramRoot: 'product'
  url: ->
    u = "#{MainAndMe.api_root}/api/v1/products/"
    u += @id if @id?
    return u

  isLiked: ->
    !@like()?.isNew()

  like: ->
    new MainAndMe.Models.Like(@get("like") || {product_id: @id})

  image: (size = "full") ->
    if @get("image")?
      img = @get("image")[size]
    unless img?
      img = "/images/fallback/product_#{size}_default.png"
    return img

class @MainAndMe.Models.NextProduct extends MainAndMe.Models.Product
  url: ->
    u = "#{MainAndMe.api_root}/api/v1/products/#{@product_id}/next_product"
    return u

class @MainAndMe.Models.PreviousProduct extends MainAndMe.Models.Product
  url: ->
    u = "#{MainAndMe.api_root}/api/v1/products/#{@product_id}/previous_product"
    return u

class @MainAndMe.Collections.Products extends MainAndMe.Collections.BaseCollection

  model: MainAndMe.Models.Product

  url: ->
    if @store_id?
      u = "#{MainAndMe.api_root}/api/v1/stores/#{@store_id}/products"
    else if @user_id?
      u = "#{MainAndMe.api_root}/api/v1/users/#{@user_id}/products"
    else
      u = "#{MainAndMe.api_root}/api/v1/users/#{@get("user_id")}/products"
    return u

class @MainAndMe.Collections.LatestProducts extends MainAndMe.Collections.Products
  url: "#{MainAndMe.api_root}/api/v1/products/latest"

class @MainAndMe.Collections.StoreLatestProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/stores/#{@store_id}/products/latest"

class @MainAndMe.Collections.CommunityLatestProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/communities/#{@community_id}/products/latest"

class @MainAndMe.Collections.SearchProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/products/search"

class @MainAndMe.Collections.NearbyProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/products/nearby"

class @MainAndMe.Collections.RandomProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/products/random"

class @MainAndMe.Collections.LikedProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/users/#{@user_id}/products/likes"

class @MainAndMe.Collections.PopularProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/products/popular"

class @MainAndMe.Collections.StorePopularProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/stores/#{@store_id}/products/popular"

class @MainAndMe.Collections.CommunityPopularProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/communities/#{@community_id}/products/popular"

class @MainAndMe.Collections.FeaturedProducts extends MainAndMe.Collections.Products
  url: ->
    "#{MainAndMe.api_root}/api/v1/products/featured"

class @MainAndMe.Collections.CommunityFeaturedProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/communities/#{@community_id}/products/featured"


class @MainAndMe.Collections.StoreFeaturedProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/stores/#{@store_id}/products/featured"

class @MainAndMe.Collections.CommunityRandomProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/communities/#{@community_id}/products/random"


class @MainAndMe.Collections.StoreRandomProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/stores/#{@store_id}/products/random"

class @MainAndMe.Collections.UserLocalProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/products/user_local"

class @MainAndMe.Collections.CategoriezedProducts extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/products/categorized?category=#{@category}"

class @MainAndMe.Collections.ItemsAdded extends MainAndMe.Collections.Products

  url: ->
    "#{MainAndMe.api_root}/api/v1/users/#{@user_id}/products/items_added"
