class @MainAndMe.Views.SearchFieldView extends MainAndMe.Views.BaseView

  el: ".nav-outer-comm"

  events:
    'keypress': 'keyPressed'
    'click .search-button-big'   : 'submitSearch'
    'click .search-icon': 'submitSearch'

  initialize:(options) ->
    super
    @initSearchParams()
    
  initSearchParams:=>
    @searchParams = {}
    #get location in initialization so it doesn't halt execution on submission
    Location.getCurrentPosition
      success: (lat, lng)=>
        @searchParams.lat = lat
        @$("#lat_field").val(lat)
        @searchParams.lng = lng
        @$("#lng_field").val(lng)

  keyPressed: (e) =>
    if e.keyCode is 13
      e?.preventDefault()
      @submitSearch()

  submitSearch: (e)=>
    @searchParams.keywords = @$("#search_input").val()
    if MainAndMe.current_page in [MainAndMe.constants.searchPage, MainAndMe.constants.storefrontsPage]
      MainAndMe.global_dispatcher.trigger("search:submit", @searchParams)
    else
      @$("#search-form").submit()
      
    

