class Data
  ###
  Constructor

  @example Constructor
     data = new Data 'http://example.org/wordpress/', {postPerPage: 5}

  @param [String] @url wordpress url
  @param [Object] opts config options
  ###
  constructor: (@url, opts) ->
    @wp = new WP @url
    @updateList = []
    @wp.lastModified (data) =>
      @lastModified = data.lastModified
      @trigger 'ready'
    @cache = new Cache {prefix: 'bingang_'}
    @events = {}

  ###
  Attach callback on data event

  @param [String] event
  @param [Function] callback
  ###
  on: (event, callback) ->
    @events[event] = {callbacks: []} unless @events[event]?
    @events[event].callbacks.push callback

  ###
  Trigger event

  @param [String] event
  @param [Object] args
  ###
  trigger: (event, args) ->
    if @events[event]?
      for callback in @events[event].callbacks
        callback args

  ###
  Attach callback on ready

  @param [Function] callback
  ###
  ready: (callback) ->
    if @lastModified?
      callback?()
    else
      @on 'ready', callback

  ###
  Get data via WP class, and cache data

  @param [String] method will call wp.method
  ###
  get: (method, args..., callback) ->
    fn = callback

    if method is 'imgs'
      fetch = (callback) ->
        args =
          type: 'get'
          url: config.indexImagesJSONP
          dataType: 'jsonp'
          jsonp: 'callback'
          success: callback
        $.ajax args
      parse = (data) ->
        html = data.page.content
        regexp = new RegExp('src="([^"]*)"', 'g')
        images = html.match(regexp)
        images = images.map (html) ->
          html.replace(new RegExp('(src=|")', 'g'), '')
      cacheID = 'imgs'

    else if method is 'links'
      fetch = (callback) ->
        args =
          type: 'get'
          url: config.linksJSONP
          dataType: 'jsonp'
          jsonp: 'callback'
          success: callback
        $.ajax args
      parse = (data) ->
        regexp = new RegExp('<a[^<>]*>[^<>]*<\/a>', 'g')
        links = data.page.content.match(regexp)
      cacheID = 'links'

    else if method is 'categorie'
      [title, page] = [args[0], args[1]]
      @categorieByTitle title, page, callback
      return

    else
      method = 'categorie' if method is 'categorieByID'
      keyArgs = args.filter (arg) -> typeof arg isnt 'function'
      cacheID = method+':'+JSON.stringify(keyArgs)
      fetch = (callback) =>
        args.push callback
        @wp[method].apply @wp, args

    update = =>
      @cache.timestamp(cacheID) < @lastModified*1000
    updateAfter = (callback) => @ready callback
    @cache.get {id: cacheID, fetch: fetch, parse: parse, update: update, success: callback, updateAfter: updateAfter}

  categorieByTitle: (title, page, callback) ->
    @get 'categories', (categories) =>
      for categorie in categories
        if categorie.title is title
          id = categorie.id
          @get 'categorieByID', {cat: id, exclude: 'content'}, page, callback
    


data = new Data config.wpUrl
