# MozRepl Bindings for Node.js
# Time-stamp: <2013-08-04 19:03:47 Zeno Zeng>
# Copyright (C) 2013 Zeno Zeng
# Licensed under MIT

net = require 'net'

class Moz
  constructor: (@port = 4242, @debug = true) ->
    @endSignal = "Firefox Client Disconnected Signal" # 随便什么字符串

  send: (javascript, callback) ->
    client = net.connect {port: @port}, ->
      console.log 'Firefox Connected'

    client.on 'end', ->
      console.log 'Firefox Disconnected'
      callback?()

    client.on 'error', (e) -> throw e

    write = (javascript) =>
      # a semicolon (;) is to force evaluation.
      javascript = ";#{javascript};\"#{@endSignal}\";"
      console.log "sent #{javascript}" if @debug
      client.write javascript

    sent = false

    client.on 'data', (data) =>
      console.log data.toString() if @debug
      unless sent
        write javascript
        sent = true
      if new RegExp(@endSignal).test(data)
        client.end()

  reload: (callback) ->
    @send "repl.look();content.window.location.reload();", callback

module.exports.Moz = Moz
