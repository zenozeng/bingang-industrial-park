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
    @debug = off
    @updateList = []
    @wp.lastModified (data) =>
      @lastModified = data.lastModified
      @trigger 'ready'
    @cache = new Cache {prefix: 'bingang_new2_'}
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
  Get data via cache.coffee
  API see require/cache.coffee Cache.get()
  ###
  getCache: (args) ->
    {id, fetch, parse, validate, success, error} = args
    update = =>
      @cache.timestamp(id) < @lastModified*1000
    updateAfter = (callback) => @ready callback
    @cache.get {id: id, fetch: fetch, parse: parse, update: update, success: success, updateAfter: updateAfter}


  imgs: (callback) ->
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
    @getCache {id: 'imgs', fetch: fetch, parse: parse, success: callback}

    
  links: (callback) ->    
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
    @getCache {id: 'links', fetch: fetch, parse: parse, success: callback}


  categorie: (args, callback) ->
    [title, page] = [args[0], args[1]]
    @get 'categories', (categories) =>
      for categorie in categories
        if categorie.title is title
          catID = categorie.id
          fetch = (callback) =>
            @wp.categorie catID, page, callback
          @getCache {id: "cat:#{catID}:page:#{page}", fetch: fetch, success: callback}

  ###
  Get data via WP class, and cache data

  @param [String] method will call wp.method
  ###
  get: (method, args..., callback) ->
    if method is 'imgs'
      @imgs callback

    else if method is 'links'
      @links callback

    else if method is 'categorie'
      @categorie args, callback

    else
      keyArgs = args.filter (arg) -> typeof arg isnt 'function'
      cacheID = method+':'+JSON.stringify(keyArgs)
      fetch = (callback) =>
        args.push callback
        @wp[method].apply @wp, args
      @getCache {id: cacheID, fetch: fetch, success: callback}

data = new Data config.wpUrl
