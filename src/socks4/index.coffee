through = require 'through'
parsers = require './parsers'
{ VERSION, COMMAND, REQUEST_STATUS, RSV } = require './const'

defaults =
  request: (infos, callback) ->
    callback REQUEST_STATUS.FAILED

exports.createHandler = ->
  step = 'request'

  methods = {}

  handler = through (chunk) ->
    switch step
      when 'request' then request.call @, chunk

  handler.set = (name, value) ->
    methods[name] = value
    return handler

  handler.set name, value for name, value of defaults

  request = (data) ->
    try
      request = parsers.request data
    catch e
      @emit 'error', e

    methods.request request, (status) =>
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

  return handler

exports[name] = value for name, value of (require './const')
