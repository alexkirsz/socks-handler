socks4 = require './socks4'
socks5 = require './socks5'

exports.handle = (stream, handlers, callback) ->
  stream.once 'data', (chunk) ->
    switch version = chunk[0]
      when socks4.VERSION
        handler = socks4.createHandler handlers
      when socks5.VERSION
        handler = socks5.createHandler handlers
      else
        callback? new Error "Unsupported SOCKS version: #{version}"
        return

    stream.pipe(handler).pipe(stream)

    # Write the first chunk.
    handler.write chunk

    handler.on 'success', ->
      stream.unpipe(handler).unpipe(stream)

    handler.on 'error', (err) ->
      callback? err

exports[4] = socks4
exports[5] = socks5
