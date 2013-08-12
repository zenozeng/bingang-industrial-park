class View

  ###
  Constructor
  ###
  constructor: ->
    @events = {}
    @data = data
    @loading()
    @data.get 'categories', (categories) ->
      html = categories.map (cat) ->
        "<li class=\"categorie\">
          <a href=\"#!/categorie/#{cat.title}\">#{cat.title}</a>
        </li>"
      $('nav ul').html html

    @data.on 'update', (args) => @refresh()

    @on 'updateneeded', (args) =>
      # show loading
      @loading()
      # scroll to top # loading is short enough, no need to scroll to top
      # $('html, body').animate({scrollTop: 0});
      # remove uyan if not post page (if post page, call it manually)
      @resetUyan() unless args.to is 'post'
      # close gallery
      gallery.close() unless args.to is 'index'

  ###
  Show loading
  ###
  loading: ->
      $('main').html '<div id="loading"><i>Loading</i><span id="bubblingG_1"></span><span id="bubblingG_2"></span><span id="bubblingG_3"></span></div>'

  ###
  Attach callback on view event

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
  Set currentView or Get it if called without any args

  @param [String] view new view
  @return [String] current view
  ###
  current: (view) ->
    if view
      # indicate ID to avoid wrong content injection when some callback delays
      # so, call $('#index').html(...) instead of $('main').html(...)
      $('main').attr 'id', view
      
      @trigger 'updateneeded', {from: @currentView, to: view}
      @currentView = view
    else
      @currentView

  ###
  Reset UYAN's vars to make reload UYAN possible

  @param [Function] callback callback to run when done
  ###
  resetUyan: (callback) ->
    resetVars =->
      for v in ["_config", "_loaded", "_c_g", "_s_g", "_style_loaded", "_style_loaded_over"]
        window["uyan"+v] = undefined
      window.uyan_config = 
        title: $('title').text()+' #滨港工业城#'
        url: config.baseUrl+window.location.hash
        su: if window.location.hash then window.location.hash.replace('#', '') else '滨港工业城'
      
    scripts = $('head script')
    pending = scripts.length
    if pending is 0
      resetVars()
      callback?()
    else
      scripts.each ->
        pending--
        src = $(this).attr('src')
        id = $(this).attr('id')
        if (src && (src.indexOf('uyan') > -1)) || (id && (id.indexOf('uyan') > -1))
          $(this).remove()
        if pending is 0
          resetVars()
          callback?()

  ###
  Callback HTML for sidebar section

  @param [Function] callback callback to handle html
  ###
  sidebar: (callback) ->
    @data.get 'links', (links) ->
      links = links.map (link) -> "<li>#{link}</li>"
      links = links.join ''
      callback '<div id="sidebar">
        <div id="search">
          <h2><i class="icon-search"></i>全站搜索</h2>
          <div id="search-box">
            <input id="search-input" type="text">
            <i class="icon-search"></i>
          </div>
        </div>
        <div id="admin">
          <h2><i class="icon-cogs"></i>后台管理</h2>
          <ul>
            <li><a href="http://wordpressz.sinaapp.com/wp-admin/post-new.php">撰写文章</a></li>
            <li><a href="http://wordpressz.sinaapp.com/wp-admin/edit.php">文章管理</a></li>
            <li><a href="http://www.uyan.cc/sites">评论管理</a></li>
            <li>
              <a href="http://wordpressz.sinaapp.com/wp-admin/post.php?post=65&action=edit">
                链接管理
              </a>
            </li>
            <li>
              <a href="http://wordpressz.sinaapp.com/wp-admin/post.php?post=43&action=edit">
                图片管理
              </a>
            </li>
          </ul>
        </div>
        <div id="links">
          <h2><i class="icon-external-link"></i>友情链接</h2>
          <ul>'+links+'</ul>
        </div>
      </div>'

  ###
  Return HTML for page nav

  @param [Interger] sum sum of pages
  @param [Interger] current current page number (starts from 1)
  ###
  pageNav: (sum, current) ->
    return '' unless sum > 1
    maxPageDistance = 3 # show ... when |sum - current| or |current - 1| > maxPageDistance

    if sum <= maxPageDistance*2
      navs = [1..sum]
    else
      if current - 1 > maxPageDistance
        left = [1, '...']
        left = left.concat [(current - maxPageDistance)...current]
      else
        left = [1...current]
      if sum - current > maxPageDistance
        right = [current..(current+maxPageDistance)]
        right = right.concat ['...', sum]
      else
        right = [current..sum]
      navs = left.concat right

    html = navs.map (i) =>
      prefix = if @current() is 'index' then "#!/page/" else "#!/#{@current()}/#{router.args[0]}/"
      page = if i is '...' then current else parseInt(i)
      href = prefix + page
      extraClass = if i is current then ' current' else ''
      "<li class=\"page#{extraClass}\"><a href=\"#{href}\">#{i}</a></li>"
      
    "<nav class=\"page-nav\"><ul>#{html.join('')}</ul></nav>"

  ###
  Load standard View for posts list page

  @param [String] container id of container, 'index', for example.
  @param [Object] posts original posts object
  @param [Interger] current current page number (starts from 1)
  ###
  list: (container, posts, currentPage) ->
    currentPage = if currentPage? then parseInt(currentPage) else 1
    pages = posts.pages
    posts = posts.posts

    return @error() if posts.length is 0

    posts = posts.map (post) -> "<article class=\"article\">
      <header>
        <a href=\"#!/archives/#{post.id}\"><span class=\"date\">#{post.date.substring(0,10)}</span> #{post.title}</a>
      </header>
    </article>"

    @sidebar (html) =>
      html += "<div id=\"sections\">
        <section class=\"section\">
          <header><h1>#{@current()}: #{router.args[0]}</h1></header>
          #{posts.join('')}
          #{@pageNav pages, currentPage}
        </section>
      </div>"
      $('#'+container).html html

  ###
  Load standard View for error page

  @param [String] title 
  @param [String] msg
  ###
  error: (title, msg) ->
    unless title? or msg?
      title = '404：没有找到您要找的内容'
      msg = '请点击 <a href="#">这里</a> 返回首页'
    @current 'error'
    html = "<div id=\"error\"><h1>#{title}</h1><p>#{msg}</p></div>"
    $('#error').html html

  ###
  Load standard View for post

  @param [Interger] id post id
  ###
  post: (id) ->
    @current 'post'
    @resetUyan =>
      @data.get 'post', id, (post) =>
        return @error() unless post
        html = "<article class=\"single\">
          <header>
            <h1>
              <a href=\"#!/archives/#{post.id}\">#{post.title}</a>
            </h1>
          </header>
          <div class=\"content\">#{post.content}</div>
          <footer id=\"comments\">#{config.uyanHTML}</footer>
        </article>"
        $('#post').html(html);

  ###
  Load standard View for index

  @param [Interger] page page
  ###
  index: (page...) ->
    @current 'index'
    gallery.start()
    
    ###
    Callback standard HTML for index sections

    @param [Function] callback function to handle html
    ###
    sections = (callback) =>
      window.indexSectionsPending = config.indexSections.length
      html = ''
      loaded = ->
        window.indexSectionsPending--
        callback?(html) if window.indexSectionsPending is 0
      for section in config.indexSections
        @data.get 'categorie', section, (data) ->
          posts = data.posts
          posts = posts.map (post) -> "<article class=\"article\">
            <header>
              <a href=\"#!/archives/#{post.id}\"><span class=\"date\">#{post.date.substring(0,10)}</span> #{post.title}</a>
            </header>
          </article>"
          html += "<section class=\"section\"><header><h1>#{section}</h1></header>#{posts.join('')}</section>"
          loaded()
        
    sections (data) =>
      @sidebar (html) ->
        html += "<div id=\"sections\">#{data}</div>"
        $('#index').html html

  ###
  Load standard View for categorie

  @param [String] categorie
  @param [Interger] page page (starts from 1)
  ###
  categorie: (categorie, page...) ->
    @current 'categorie'
    @data.get 'categorie', categorie, page[0], (posts) =>
      @list 'categorie', posts, page[0]

  ###
  Load standard View for search

  @param [String] keyword
  @param [Interger] page page (starts from 1)
  ###
  search: (keyword, page...) ->
    @current 'search'
    @data.get 'search', keyword, page[0], (posts) =>
      @list 'search', posts, page[0]

  ###
  Refresh current view
  ###
  refresh: -> router.apply()

view = new View

$ ->
  submitSearch = ->
    keyword = $('#search-input').val()
    return unless keyword.length > 0
    router.navigate "#!/search/#{keyword}"
  $('body').on 'click', '#search-box i', submitSearch
  $('body').on 'keydown', '#search-input', (e) -> submitSearch() if e.keyCode is 13
