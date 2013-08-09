###
Copyright (C) 2013 Zeno Zeng

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

class WP
  ###
  Constructor

  @example Constructor
     wp = new WP 'http://example.org/wordpress/', {postPerPage: 5}

  @param [String] @url wordpress url
  @param [Object] opts config options
  ###
  constructor: (@url, opts) ->
    @opts =
      useFakeData: false # use fakeData for offline testing
      postPerPage: 10
      useComments: false
    if opts
      @opts[key] = value for key, value of opts
      
  ###
  Get data according to WordPress's JSON API
  @see http://wordpress.org/plugins/json-api/other_notes/

  @example Constructor
    wp = new WP 'http://example.org/wordpress/', {postPerPage: 5}
    @get 'get_category_index', callback

  @param [String] method method
  @param [Object] obj Query parameters
  @param [Function] callback function to handle results
  ###
  get: (method, obj..., callback) ->
    obj = if obj.length > 0 then obj[0] else {}
    if @opts.useFakeData
      return fake method, obj, callback
    obj.json = if method then method else 1
    args =
      type: 'get'
      url: @url
      dataType: 'jsonp'
      jsonp: 'callback'
      data: obj
      success: callback
    $.ajax args
    
  ###
  Return fake data for local testing

  @param [String] method method
  @param [Object] obj Query parameters
  @param [Function] callback function to handle results
  ###
  fake: (method, obj, callback) ->
    method = 'get_posts' if method is 'get_recent_posts'
    $.get 'fake/'+method+'.json', callback

  ###
  Get single post object by id

  @param [Interger] id Post ID
  @param [Function] callback function to handle results
  ###
  post: (id, callback) ->
    @get 'get_post', {post_id: id}, (data) ->
      callback data.post
    
  ###
  Get posts according to WordPress's WP_Query parameters

  @see http://codex.wordpress.org/Class_Reference/WP_Query#Parameters

  @example Query Example
     wp = new WP
     wp.posts {category_name='staff', tag='work'}, 2, callback

  @param [Object] args WP_Query parameters
  @param [Interger] page Paged Number
  @param [Function] callback function to handle results

  @note Will return recent posts if args is {}
  @note The one default parameter is ignore_sticky_posts=1 (this can be overridden).
  ###
  posts: (args, page..., callback) ->
    if JSON.stringify args is '{}'
      method = 'get_recent_posts'
    else
      method = 'get_posts'
    args.posts_per_page = @opts.postsPerPage
    if page.length > 0
      args.paged = page[0] # paged (int) - number of page. Show the posts that would normally show up just on page X when using the "Older Entries" link.
    @get method, args, callback
    
  ###
  Get posts whose categorie is TITLE

  @param [String] title the title of categorie
  @param [Interger] page Paged Number
  @param [Function] callback function to handle results
  ###
  categorie: (title, page..., callback) ->
    @categories (categories) =>
      for categorie in categories
        if categorie.title is title
          id = categorie.id
          @posts {cat: id}, page[0], callback

  ###
  Get posts whose tag is TITLE

  @param [String] title the title of tag
  @param [Interger] page Paged Number
  @param [Function] callback function to handle results
  ###
  tag: (title, page..., callback) ->
    @tags (tags) =>
      for tag in tags
        if tag.title is title
          id = tag.id
          @posts {tag_id: id}, page[0], callback
        

  ###
  Search posts with keyword

  @param [String] keyword
  @param [Interger] page Paged Number
  @param [Function] callback function to handle results
  ###
  search: (keyword, page..., callback) ->
    @posts {s: keyword}, page[0], callback


  ###
  Get all active categories

  @param [Function] callback function to handle results
  @return [Array] categories, sth like [{"id":4,"slug":"cat","title":"catTitle","description":"","parent":0,"post_count":1}, {...}, {...}]
  ###
  categories: (callback) ->
    @get 'get_category_index', (obj) ->
      callback obj.categories

  ###
  Get all active tags

  @param [Function] callback function to handle results
  @return [Array] tags, sth like [{"id":8,"slug":"tagSlut","title":"tagTitle","description":"","post_count":1}, {...}, {...}]
  ###
  tags: (callback) ->
    @get 'get_tag_index', (obj) ->
      callback obj.tags
        

  ###
  Submit a comment on a POST

  @param [Interger] postId id of post
  @param [String] name the name of current visitor
  @param [String] email the email of current visitor
  @param [String] content comment content
  @param [Function] callback function to handle results
  ###
  comment: (postId, name, email, content, callback) ->
    args = {post_id: postId, name: name, email: email, content: content}
    @get 'respond.submit_comment', args, callback


  ########################################################
  #
  # PART II
  # 
  # WP-JSON-API-Extra
  #
  # https://github.com/zenozeng/wp-json-api-extra/
  #
  #########################################################


  ###
  Get data according to WordPress's JSON API Extra

  @param [String] method method
  @param [Object] data Query parameters
  @param [Function] callback function to handle results
  ###
  getExtra: (method, data, callback) ->
    data.jsonextra = method
    args =
      type: 'get'
      url: @url
      dataType: 'jsonp'
      jsonp: 'callback'
      data: data
      success: callback
    $.ajax args

  ###
  Get Last Modified Time (Changes when a post/page modified), will get sth like this: {"lastModified":1375794257}

  @param [Function] callback function to handle results
  ###
  lastModified: (callback) ->
    @getExtra 'lastModified', {}, callback
