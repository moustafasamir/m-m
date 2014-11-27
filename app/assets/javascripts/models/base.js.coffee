class @MainAndMe.Models.BaseModel extends Backbone.Model

  @_cache = {}

  can: (action) ->
    @get("permissions")[action]

  cant: (action) ->
    !@can(action)

  addThisTitle: =>
    title = if @get("name")
      @get("name")
    else if @get("title")
      @get("title")
    else
      $("title").text()
    return "Main and Me - #{title}"

  addThisDescription: =>
    if @get("description")
      return @get("description")
    else if @get("body")
      return @get("body")
    else
      return ""

  # fetch: (options = {}) =>
  #   if options.no_cache? is true
  #     super(options)
  #   else
  #     if MainAndMe.Models.BaseModel._cache[@url()]?
  #       @set(MainAndMe.Models.BaseModel._cache[@url()], silent: true)
  #       if options.success?
  #         options.success(@)
  #     else
  #       super(options)

  # parse: (response) =>
  #   MainAndMe.Models.BaseModel._cache[@url()] = response
  #   super

  # modelName: ->
  #   @_className()
    
  # _className: ->
  #   if @constructor and @constructor.toString
  #     arr = @constructor.toString().match(/function\s*(\w+)/)
  #     if arr and arr.length is 2
  #       return arr[1]
  #   return undefined

class @MainAndMe.Collections.BaseCollection extends Backbone.Collection
  fetchCommunityID: =>
    @data.community_id = @getCommunityID()

  getCommunityID: =>
    $.cookie("community_id", {path: "/"}) if $.cookie("community_id", {path: "/"})

  setLocation:(options = {}) =>
    if options.locationCallBack?
      Location.getCurrentPosition
        success: (lat, lng)=>
          @data = {} unless @data?
          @data.lat = lat
          @data.lng = lng
          options.locationCallBack()
        error: =>
          if options.locationError?
            options.locationError() 
          else
            options.locationCallBack()

  fetch: (options = {}) =>
    if @data?
      dt = {}
      for key, value of @data
        dt[key] = value
      options.data ||= {}
      for key, value of options.data
        dt[key] = value
      options.data = dt
    xhr = super(options)
    xhr.then =>
      if xhr.getResponseHeader("X-Pagination")?
        @pagination = new MainAndMe.Models.Pagination(JSON.parse(xhr.getResponseHeader("X-Pagination")))
        @trigger("pagination:updated")
        # console?.log @pagination
    return xhr

  data: {}