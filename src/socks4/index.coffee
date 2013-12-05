through = require 'through'
parsers = require './parsers'
defaults = require './defaults'
{ VERSION, COMMAND, REQUEST_STATUS, RSV } = require './const'

exports.createHandler = (_handlers) ->
  step = 'request'

  handlers = {}
  handlers[name] = value for name, value of defaults
  handlers[name] = value for name, value of _handlers

  onwrite = (chunk) ->
    switch step
      when 'request' then request.call @, chunk

  request = (data) ->
    try
      request = parsers.request data
    catch e
      @emit 'error', e

    handlers.request request, (status) =>
      @push new Buffer [
        RSV
        status
        request.portBuffer... # Should be ignored anyway
        request.hostBuffer... # Should be ignored anyway
      ]

      if status isnt REQUEST_STATUS.GRANTED
        @push null
      else
        step = 'ignore'
        @emit 'success'

  through onwrite

exports[name] = value for name, value of (require './const')
