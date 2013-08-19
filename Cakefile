fs = require 'fs'
net = require 'net'

{print} = require 'sys'
{spawn} = require 'child_process'
{Moz} = require './build/moz.coffee'
{Manifest} = require './build/manifest.coffee'

moz = new Moz 4242, false

config =
  minify: off

lessc = (callback) ->
  command = spawn 'lessc', ['-x', 'css/styles.less', 'css/styles.css']
  command.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  command.stdout.on 'data', (data) ->
    print data.toString()
  command.on 'exit', (code) ->
    callback?() if code is 0


build = (callback) ->
  src = ['require/wp', 'require/cache', 'config', 'data', 'gallery', 'view', 'routes']
  src = src.map (each) -> 'src/'+each + '.coffee'
  args = ['--join', 'js/main.js', '--compile', '--bare'].concat src
  coffee = spawn 'coffee', args
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    minify ->
      callback?() if code is 0

minify = (callback) ->
  unless config.minify
    return callback?()
  task = spawn 'uglifyjs', ['--screw-ie8', 'js/main.js', '-o', 'js/main.min.js']
  task.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  task.stdout.on 'data', (data) ->
    print data.toString()
  task.on 'exit', (code) ->
    fs.unlink 'js/main.js', ->
      callback?() if code is 0

    
task 'build', 'Build js/ from src/', ->
  build ->
    lessc()

task 'watch', 'Watch and Build', ->
  watch = require 'watch'
  watch.createMonitor 'css', (monitor) ->
    monitor.on "changed", (f, curr, prev) ->
      console.log "Recompile\n"
      build ->
        lessc ->
          moz.reload()

