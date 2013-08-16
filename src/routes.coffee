class Router
  constructor: () ->
    @routes = {}
    $(window).on 'hashchange', =>
      @apply()

  add: (route, callback) ->
    route = route.replace new RegExp(':\\w+', 'g'), '([^\/]+)'
    route = route.replace new RegExp('/', 'g'), '\\/'
    @routes["^#{route}$"] = callback

  navigate: (url) ->
    url = url.split('#').pop()
    window.location.hash = '#'+url

  current: -> window.location.hash

  apply: ->
    path = window.location.hash.toString().split('#').pop()
    for reg, fn of @routes
      regexp = new RegExp(reg)
      if regexp.test path
        @args = regexp.exec(path).slice(1) # 存下参数，方便变更url时使用
        fn.apply window, @args

router = new Router

routes =
  '': -> view.index()
  "!/page/:page": (page) -> view.index page
  "!/archives/:id": (id) -> view.post id
  "!/search/:query": (query) -> view.search query
  "!/search/:query/:page": (query, page) -> view.search query, page
  "!/tag/:tag": (tag) -> view.tag tag
  "!/tag/:tag/:page": (tag, page) -> view.tag tag, page
  "!/categorie/:cat": (cat) -> view.categorie cat
  "!/categorie/:cat/:page": (cat, page) -> view.categorie cat, page
  "!/error": -> view.error()
  
router.add route, fn for route, fn of routes
router.apply()    

$('body').on 'click', 'a', (e) ->
  href = $(this).attr('href')
  return unless href
  e.preventDefault()
  e.stopPropagation()
  if href.indexOf('#') is 0
    router.navigate href
  else
    window.location.href = href
