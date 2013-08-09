class Gallery

  ###
  Constructor

  @param [Array] imgs src of imgs
  ###
  constructor: ->
    @readyCallbacks = []
    @imgs = []
    @width = 900 # gallery box width
    @height = 200 # gallery box height
    @loaded = false

  ###
  Set imgs

  @param [Array] imgs src of imgs
  ###
  set: (imgs) ->
    @imgs = imgs
    for callback in @readyCallbacks
      @ready callback
    @readyCallbacks = []

  ###
  Ready

  @param [Function] callback function to call when gallery was ready
  ###
  ready: (callback) ->
    if @imgs.length > 0
      callback?()
    else
      @readyCallbacks.push callback

  ###
  Load first image adn then Show gallery
  ###
  start: ->
    show = =>
      $('#gallery #img').html("<img src=\"#{@imgs[0]}\" alt=\"gallery-img\">")
      @count++
      interval = => ((that)-> that.next())(this)
      @interval = setInterval interval, 3000
      @setImgScale ->
        $('#gallery').slideDown() unless $('#gallery').is(':visible')
    @ready =>
      @count = 0
      if @loaded
        show()
      else
        # load first image before show #gallery
        img = new Image()
        img.src = @imgs[0]
        img.onload = =>
          @loaded = true
          show()

  ###
  Hide Gallery and  clear interval
  ###
  close: ->
    $('#gallery').hide()
    clearInterval @interval if @interval?

  ###
  Preload next image
  ###
  preload: ->
    if @count < @imgs.length
      nextImage = @imgs[@count]
      (new Image()).src = nextImage

  ###
  Switch to next image, and preload the next one
  ###
  next: ->
    index = @count % @imgs.length
    img = @imgs[index]
    @count++
    $('#gallery #img').fadeOut 400, =>
      $('#gallery #img').html("<img src=\"#{img}\" alt=\"gallery-img\">")
      @setImgScale =>
        $('#gallery #img').fadeIn 400
        @preload()
    

  ###
  Resize the image to fit scale
  ###
  setImgScale: (callback) ->    
    $this = $('#gallery #img img')
    $this.attr('src', $(this).attr('src')).load =>
      $this = $('#gallery #img img')
      imgWidth = this.width
      imgHeight = this.height
      imgScale = imgWidth / imgHeight
      boxWidth = @width
      boxHeight = @height
      boxScale = boxWidth / boxHeight
      if(imgScale > boxScale) 
        $this.height(boxHeight);
        newWidth = boxHeight / imgHeight * imgWidth
        left = (newWidth - boxWidth) / 2
        $this.css({height: boxHeight, width: 'auto', left: -left, top: 0})
      else
        newHeight = boxWidth / imgWidth * imgHeight
        top = (newHeight - boxHeight) / 2
        $this.css({height: 'auto', width: boxWidth, left: 0, top: -top})
      callback?()

gallery = new Gallery
data.get 'imgs', (imgs) -> gallery.set imgs
  
