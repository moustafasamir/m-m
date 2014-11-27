class @MainAndMe.Views.GiftsView extends MainAndMe.Views.BaseView

  el: "#gifts"  

  events:
    'click #featured_button': 'showFeaturedProducts' 
    'click #newest_button': 'showNewestProducts' 
    'click #popular_button': 'showPopularProducts' 
    'click #random_button': 'showRandomProducts' 

  initialize: ->
    super
    @_getState()
    $("#gifts_up_nav").addClass("sltd")
    @template = JST['products/gifts_view']
    @render()
    @filter_by_price("all")

  render: =>
    @$el.html(@_renderTemplate())        

  renderCollection: =>
    @$('#results').html(new MainAndMe.Views.ProductsGridView(collection: @collection, display_price: true).el)

  showFeaturedProducts: =>
    @showProductsCollection('featured_button', new MainAndMe.Collections.FeaturedProducts())

  showNewestProducts: =>
    @showProductsCollection('newest_button', new MainAndMe.Collections.LatestProducts())

  showPopularProducts: =>
    @showProductsCollection('popular_button', new MainAndMe.Collections.PopularProducts())

  showRandomProducts: =>
    @showProductsCollection('random_button', new MainAndMe.Collections.RandomProducts())

  showProductsCollection:(button_id, collection) =>
    e?.preventDefault()
    @mark_selected_button(button_id)
    @collection = collection
    @collection.data.community_id = @getCommunityID()
    @collection.data.price_range =  if @price_range?
                                      @price_range
                                    else
                                      "any"
    @collection.setLocation
      locationCallBack: => @renderCollection()

  mark_selected_button: (button_id) =>
    @$("##{button}").removeClass("sltd") for button in ['random_button', 'newest_button', 'popular_button', 'featured_button']
    @$("##{button_id}").addClass("sltd")

  filter_by_price:(price_range)=>
    if price_range == "all"
      @price_range = null
    else
      @price_range = price_range

    @showRandomProducts()

  getCommunityID: =>
    new MainAndMe.Views.StatesView().getCommunityID()
