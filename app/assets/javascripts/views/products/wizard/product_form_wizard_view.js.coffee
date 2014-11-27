class MainAndMe.Views.ProductFormWizardView extends MainAndMe.Views.BaseView

  template: JST['products/wizard/_form']
  
  className: 'image-unit'

  initialize: ->
    super
    @imgFile = @options.imgFile
    @model = new MainAndMe.Models.Product()
    @render()

  render: =>
    $(@el).html(@_renderTemplate())
    @showThumbnail()
    @form = new MainAndMe.Form(@$("form"))
    @form.get("price").html(@form.priceRangeAsOptions())    
    @form.bind(@model, silent: true)
    #Hide the uploading divs
    @$(".uploading").hide()
    @$(".uploading-text").hide()
    return @

  showThumbnail: =>
    file = @imgFile    
    imageType = /image.*/
    if(!file.type.match(imageType))
      console.log("Not an Image")         
    else    
      image = @$(".canvas-draw")[0]
      image.file = file;    
      reader = new FileReader()
      reader.onload = ((aImg)->
        return (e)->
          aImg.src = e.target.result
      )(image)      
      ret = reader.readAsDataURL(file)
      canvas = document.createElement("canvas")
      ctx = canvas.getContext("2d")
      image.onload= ->
        ctx.drawImage(image,100,100)          