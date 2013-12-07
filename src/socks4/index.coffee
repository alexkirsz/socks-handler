through = require 'through'
parsers = require './parsers'
{ VERSION, COMMAND, REQUEST_STATUS, RSV } = require './const'

events =
  request: (infos, callback) ->
    callback REQUEST_STATUS.FAILED

exports.createHandler = ->
  step = 'request'

  handler = through (chunk) ->
    switch step
      when 'request' then request.call @, chunk

  handler.version = VERSION

  handler.on name, value for name, value of events

  handler.on 'newListener', (event, listener) ->
    if event of events and events[event] in (handler.listeners event)
      handler.removeListener event, events[event]

  request = (data) ->
    try
      request = parsers.request data
    catch e
      @emit 'error', e
      return

    @emit 'request', request, (status) =>
      @push new Buffer [
        RSV
        status
        request.portBuffer...
        request.hostBuffer...
      ]

      if status isnt REQUEST_STATUS.GRANTED
        @push null
      else
        step = 'ignore'
        @emit 'success'

  return handler

exports[name] = value for name, value of (require './const')
