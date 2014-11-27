class @MainAndMe.Views.LikeView extends MainAndMe.Views.BaseView

  className: ''

  template: JST['products/like_view']
  
  events:
    'click': 'likeClicked'

  initialize: ->
    super
    $(this.el).addClass(@options.class)
    @liked_item = @options.liked_item
    @like = @liked_item.like()
    @render()

  render: =>
    $(@el).html(@_renderTemplate(like: @like))
    if !@like.isNew()
      @$(".like-icon").attr("src", "/assets/unlike-btn.png")
    return @

  likeClicked: (e) =>
    e?.preventDefault()    
    @_requires_auth =>
      if @like.isNew()
        if @current_user?
          @like.save {}, 
            success: => @render()
      else
        @like.destroy
          success: =>
            @like.id = null
            @render()