class @MainAndMe.Views.BaseView extends Backbone.View

  helpers: MainAndMe.Helpers

  can: MainAndMe.Helpers.can
  cant: MainAndMe.Helpers.cant

  initialize: ->
    @store = MainAndMe.current_store
    @current_user = MainAndMe.current_user

  _requires_auth: (callback) =>
    if @current_user?.isNew()
      window.location = Routes.new_user_session_path()
    else
      callback() if callback?

  _handleErrors: (errors, form) =>
    errors = errors['errors'] if errors['errors']?
    for key, messages of errors
      mess = _.flatten([messages])
      el = form.get(key)
      if el.html()?
        el.closest(".control-group").addClass("error")
        for message in mess
          el.after("<span class='help-inline'>#{message}</span>")
      else
        for message in mess
          console.log "#{key} #{message}"
          # Flash.message("alert", "#{key} #{message}")


  _clearErrors: =>
    @$(".control-group").removeClass("error")
    @$(".help-inline").remove()

  _renderTemplate: (options = {}) =>
    options["state"] ||= @state if @state?
    options["store"] ||= @store if @store?
    options["current_user"] ||= @current_user if @current_user?
    options["model"] ||= @model if @model?
    options["collection"] ||= @collection if @collection?
    options["form"] ||= @form if @form?
    options["helpers"] ||= @helpers
    options["can"] = @can
    options["cant"] = @cant
    template = options["template"] || @template
    template(options)

  _isStoreOwner: =>
    @store?.get("user_id")? and @current_user?.get("id")? and @store.get("user_id") is @current_user.get("id")
    
  _mediaGrid: (collection, callback) =>
    $("#no_results").hide()
    @$(".l-prod-v-row:not(.offlimits)").html("")
    if collection.models.length > 0
      collection.forEach (object) =>
        @_addToMediaGrid(object, callback)
    else
      $("#no_results").show()

  _nextAvailableMediaGrid: =>
    cols = @$(".l-prod-v-row:not(.offlimits)")
    lengths = for col in cols
      length = $('.v-row-txt, .followers-txt', col).length
      # length = $(col).height()
      {length: length, column: col}
      
    lengths = lengths.sort (a, b) ->
      a.length - b.length

    next = $(lengths[0].column)
    return next

  _addToMediaGrid: (object, callback) =>
    callback(object, @_nextAvailableMediaGrid())

  _renderCollection: =>
    @_mediaGrid @collection, (object, column) =>
      @_renderOne(object, column)

  _handleAdd: (object) =>
    @_renderOne(object)

  _renderOne: (object, column = @_nextAvailableMediaGrid()) =>
  
  _change_url: (url, title="Title")  =>
    window.history.pushState("object or string", title, url);

  _renderSocialButtons: =>    
    FB.XFBML.parse()
    twttr.widgets.load() 
    gapi.plusone.go()

  _preloadImages:(images)=>
    for imageSrc in images
      image = new Image()
      image.src = imageSrc

  _getState: =>
    unless @state?
      @state = $.cookie("state", {path: "/"}) if $.cookie("city", {path: "/"})
    @state

  _getCity: =>
    unless @city?
      @city = $.cookie("city", {path: "/"}) if $.cookie("state", {path: "/"})
    @city
