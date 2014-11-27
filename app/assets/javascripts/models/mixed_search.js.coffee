class @MainAndMe.Models.MixedSearch extends MainAndMe.Models.BaseModel

  @priceRanges:
    25: "$0 - $25"
    50: "$25 - $50"
    100: "$50 - $100"
    200: "$100 - $200"
    500: "$200 - $500"
    1000: "$500 -$1000"
    10000: "$1000 and up"

  url: ->
    "#{MainAndMe.api_root}/api/v1/search/mixed"

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

  address:->
    addressText = ""
    addressText += "#{@get('street')}, " if @get('street')
    addressText += "#{@get('city')}, " if @get('city')
    addressText += "#{@get('state')}" if @get('state')


class @MainAndMe.Collections.MixedSearch extends MainAndMe.Collections.BaseCollection

  model: MainAndMe.Models.MixedSearch

  url: ->
    "#{MainAndMe.api_root}/api/v1/search/mixed"