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
      for updateArgs in @updateList
        @update.apply this, updateArgs
    @cache = {}
    @cacheKeyPrefix = 'bingang'
    @useLocalStorage = true
    # turn off localStorage if not supported
    unless window.localStorage?
      @useLocalStorage = false
    @debug = false
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
  Write Data to RAM Cache & localStorage

  @param [String] cacheKey
  @param [Object] data
  ###
  save: (cacheKey, data) ->
    # if is post list, cache each post first
    if data? && data.posts?
      for post in data.posts
        @save "post:[\"#{post.id}\"]", post
    unless cacheKey.indexOf(@cacheKeyPrefix) is 0
      cacheKey = @cacheKeyPrefix+':'+cacheKey 
    console.log "save:"+cacheKey if @debug
    @cache[cacheKey] = data # Save in RAM
    data =
      data: data
      timestamp: @lastModified # use server's timestamp to avoid local diff
    console.log data if @debug
    if @useLocalStorage
      try 
        localStorage.setItem(cacheKey, JSON.stringify(data))
      catch e
        if e.name is 'QUOTA_EXCEEDED_ERR'
          # remove all localStorage items with @cacheKeyPrefix
          for key of localStorage
            if key.indexOf(@cacheKeyPrefix) is 0
              localStorage.removeItem key

  ###
  Update Data, starts when @lastModified is ready

  @param [String] cacheKey
  @param [Function] fetch function to fetch data, with an arg to handle callback
  @param [Function] parse function to parse data, returning parsed result
  ###
  update: (cacheKey, fetch, parse) ->
    if @lastModified?
      console.log 'testUpdate:'+cacheKey if @debug
      cacheItem = JSON.parse(localStorage.getItem(cacheKey))
      cacheTime = if (cacheItem && cacheItem.timestamp?) then cacheItem.timestamp else 0
      console.log [cacheTime, @lastModified, cacheTime - @lastModified] if @debug
      return if cacheTime >= @lastModified # cache was still the lastest data, no need to update
      console.log 'update:'+cacheKey if @debug
      fetch (data) =>
        data = if parse then parse(data) else data
        @save cacheKey, data
        @trigger 'update', {cacheKey: cacheKey}
    else
      @updateList.push [cacheKey, fetch, parse]

  ###
  Get Data, try to get from cache first

  @param [String] cacheKey
  @param [Function] fetch function to fetch data, with an arg to handle callback
  @param [Function] parse function to parse data, returning parsed result
  @param [Function] callback function to handle data

  @note if data was loaded from localStorage, will automatally update data in the backend
  ###
  fetch: (cacheKey, fetch, parse..., callback) ->
    unless cacheKey.indexOf(@cacheKeyPrefix) is 0
      cacheKey = @cacheKeyPrefix+':'+cacheKey 
    if @cache[cacheKey]
      console.log "RAM:"+cacheKey if @debug
      callback @cache[cacheKey]
    else
      if @useLocalStorage && localStorage.getItem(cacheKey) && JSON.parse(localStorage.getItem(cacheKey)).timestamp
        console.log "localStorage:"+cacheKey if @debug
        callback JSON.parse(localStorage.getItem(cacheKey)).data
        @update cacheKey, fetch, parse[0]
      else
        console.log "fetch:"+cacheKey if @debug
        fetch (data) =>
          data = if parse[0] then parse[0] data else data
          callback data
          @update cacheKey, (fn) -> fn(data) # use @update instaed of @save to make sure @lastModified was loaded
  
  ###
  Get data via WP class, and cache data

  @param [String] method will call wp.method
  ###
  get: (method, args..., callback) ->
    fn = callback
    return @imgs callback if method is 'imgs'
    return @links callback if method is 'links'
    keyArgs = args.filter (arg) -> typeof arg isnt 'function'
    cacheKey = method+':'+JSON.stringify(keyArgs)
    fetch = (callback) =>
      args.push callback
      @wp[method].apply @wp, args
    @fetch cacheKey, fetch, null, callback

  ###
  Get index imgs' urls

  @param [Function] callback function to handle data
  ###
  imgs: (callback) ->
    cacheKey = 'imgs'
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
    @fetch cacheKey, fetch, parse, callback
      
  ###
  Get links for #links

  @param [Function] callback function to handle data
  ###
  links: (callback) ->
    cacheKey = 'links'
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
    @fetch cacheKey, fetch, parse, callback

data = new Data config.wpUrl
