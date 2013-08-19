###
Cache.coffee

Copyright (C) 2013 Zeno Zeng

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

class Cache

  ###
  Constructor

  @example Constructor
     cache = new Cache {prefix: "myprefix_"}

  @param [Object] opts config options
  ###
  constructor: (opts) ->
    @events = {}
    @tmp = {}
    @queue = {}
    @debug = true
    defaults =
      prefix: 'myCachePrefix_'
    @opts = _.extend defaults, opts

    @storage = null
    if $? && $.jStorage?
      @storage =
        backend: 'jStorage'
        keys: $.jStorage.index
        getItem: $.jStorage.get
        setItem: $.jStorage.set
        removeItem: $.jStorage.deleteKey
    if window.localStorage?
      @storage =
        backend: 'localStorage'
        keys: ->
          keys = []
          keys.push key for key of window.localStorage
          keys
        getItem: window.localStorage.getItem
        setItem: window.localStorage.setItem
        removeItem: window.localStorage.setItem

  ###
  Trigger event

  @param [String] event event name
  @param [Object] args event args
  ###
  trigger: (event, args) ->
    if @events[event]?
      for callback in @events[event].callbacks
        callback args

  ###
  Attach callback on data event

  @param [String] event event name
  @param [Function] callback function to handle event
  ###
  on: (event, callback) ->
    @events[event] = {callbacks: []} unless @events[event]?
    @events[event].callbacks.push callback

  ###
  Get data, return from cache first, and update it in the background

  @example Get Data
    cache = new Cache {prefix: "myprefix_"}
    cache.get
      id: 'post-123'
      fetch: (success, error) ->
        $.ajax {url: 'http://eample.com/abc', success: success, error: error}
      parse: (data) ->
        JSON.parse data
      validate: (data) ->
        data.status is 'ok'
      # tell whether should update data in the background, could be true || false || function 
      update: () ->
        lastModified > lastUpdated
      success: successCallback
      error: errorCallback

  @param [Object] args data args
  ###
  get: (args) ->
    [id, fetch, parse, validate, update, success, error] = args
    id = @opts.prefix + id
    unless parse
      parse = (data) -> data
    unless validate
      validate (data) = -> true
    update = true unless update?
    update = update() if typeof update is 'function'
    
    if @cache[id]?
      # RAM Cache exists
      callback?(@cache[id])
    else
      if @storage?
        data = @storage.getItem id
        if data? && data.timestamp? && data.data?
          # storage Cache exists
          callback?(data.data)
          if update
            args.callback = null
            @fetch(args)
        else
          # no cache exist
          @fetch args

  ###
  Return last update timestamp of cache (microtime)

  @param [String] id cache id
  @return [Interger] time stamp
  ###
  timestamp: (id) ->
    id = @opts.prefix + id
    if @storage?
      data = @storage.getItem id
      if data? && data.timestamp? && data.data?
        return data.timestamp
    null

  ###
  Fetch data, and update it in the background

  @example Fetch Data
    cache = new Cache {prefix: "myprefix_"}
    cache.fetch
      id: 'post-123'
      fetch: (success, error) ->
        $.ajax {url: 'http://eample.com/abc', success: success, error: error}
      parse: (data) ->
        JSON.parse data
      validate: (data) ->
        data.status is 'ok'
      # tell whether should update data in the background, could be true || false || function 
      update: () ->
        lastModified > lastUpdated
      success: successCallback
      error: errorCallback

  @param [Object] args data args
  ###
  fetch: (args) ->
    [id, fetch, parse, validate, success, error] = args
    if @queue[id]
      # already exists in queue
      callbackFn = _.once(callback)
      @on 'load', (e) ->
        if e.id is id
          callbackFn e
    else
      fetch (data) =>
        data = parse data
        if validate(data)
          @trigger 'load', {id: id, data: data}
          @save id, data
          success(data)
        else
          error {name: 'DATA_INVALID_ERR'}


  ###
  Save data to cache
  
  @param [String] id data's Cache ID
  @param [Object] data data
  ###
  save: (id, data) ->
    @cache[id] = data
    data = {timestamp: (new Date()).getTime(), data: data}
    if @storage?
      try
        @storage.setItem id, data
      catch e
        # clear storage if exceeded
        if e.name is 'QUOTA_EXCEEDED_ERR'
          @clear()
          try
            @storage.setItem id, data
          catch e
            false

      if @storage.backend is 'jStorage'
        unless @storage.getItem(id)?
          # if saving fails
          @clear() 
          @storage.setItem id, data

      
  ###
  Clear all storage items with prefix
  ###
  clear: ->
    for key in @storage.keys()
      if key.indexOf @opts.prefix is 0
        @storage.removeItem key
