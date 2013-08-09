# Copyright (C) 2013 Zeno Zeng
# licensed under MIT License

fs = require 'fs'

class Manifest
  constructor: ->
    @manifest = 'cache.manifest'
    @cache = new RegExp '.*\\.(css|js|html|yml|woff)$'
    @ignore = new RegExp '(\\.git|#)'

  gen: (callback) ->
    console.log "gen #{@manifest}"
    content = "CACHE MANIFEST\n# Time-stamp: <#{new Date().getTime()} Cake Script>\n"
    handle = (file) =>
      if @cache.test file
        unless @ignore.test file
          file = file.replace new RegExp('^\\.\\/'), ''
          content += "#{file}\n"

    walk = (dir, callback) =>
      if @ignore.test(dir)
        return callback []
      files = []
      fs.readdir dir, (err, list) =>
        throw err if err
        pending = list.length
        callback files unless pending
        list.forEach (file) =>
          file = dir + '/' + file
          if @ignore.test(file)
            callback files unless --pending
          else
            fs.stat file, (err, stats) ->
              throw err if err
              if stats && stats.isDirectory()
                walk file, (res) ->
                  files = files.concat res
                  callback files unless --pending
              else
                files.push file
                callback files unless --pending

    walk '.', (files) =>
      for file in files
        handle file

      fs.writeFile @manifest, content, (err) ->
        throw err if err
        console.log "update manifest"
        callback?()

module.exports.Manifest = Manifest
