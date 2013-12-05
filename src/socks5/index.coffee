net = require 'net'
ip = require 'ip'
through = require 'through'
parsers = require './parsers'
{ VERSION, AUTH_METHOD, COMMAND, AUTH_STATUS, ADDRTYPE, REQUEST_STATUS, RSV } = require './const'

defaults =
  handshake: ({ methods }, callback) ->
    if AUTH_METHOD.NOAUTH in methods
      callback AUTH_METHOD.NOAUTH
    else
      callback AUTH_METHOD.NO_ACCEPTABLE_METHOD

  auth: (infos, callback) ->
    callback AUTH_STATUS.FAILURE

  request: (infos, callback) ->
    callback REQUEST_STATUS.SERVER_FAILURE

exports.createHandler = ->
  step = 'handshake'
  authMethod = -1

  methods = {}

  handler = through (chunk) ->
    switch step
      when 'handshake' then handshake.call @, chunk
      when 'authentication' then authentication.call @, chunk
      when 'request' then request.call @, chunk

  handler.version = VERSION

  handler.set = (name, value) ->
    methods[name] = value
    return handler

  handler.set name, value for name, value of defaults

  handshake = (data) ->
    try
      handshake = parsers.handshake data
    catch e
      @emit 'error', e
      return

    methods.handshake handshake, (method) =>
      @push new Buffer [VERSION, method]

      if method is AUTH_METHOD.NO_ACCEPTABLE_METHOD
        @push null
      else if method is AUTH_METHOD.NOAUTH
        step = 'request'
      else
        authMethod = method
        step = 'authentication'

  authentication = (data) ->
    try
      auth = parsers.auth data, authMethod
    catch e
      @emit 'error', e
      return

    methods.auth auth, (status) =>
      @push new Buffer [VERSION, status]

      if status isnt AUTH_STATUS.SUCCESS
        @push null
      else
        step = 'request'

  request = (data) ->
    try
      request = parsers.request data
    catch e
      @emit 'error', e
      return

    methods.request request, (status, localPort, localAddress) =>
      if localPort
        portBuffer = new Buffer 2
        portBuffer.writeUInt16BE localPort, 0
      else
        { portBuffer } = request

      if localAddress
        if net.isIPv4 localAddress
          addrType = ADDRTYPE.IPV4
          hostBuffer = ip.toBuffer localAddress
        else if net.isIPv6 localAddress
          addrType = ADDRTYPE.IPV6
          hostBuffer = ip.toBuffer localAddress
        else
          addrType = ADDRTYPE.DOMAIN
          hostBuffer = new Buffer localAddress
      else
        { addrType, hostBuffer } = request

      @push new Buffer [
        VERSION
        status
        RSV
        ADDRTYPE.IPV4
        [0, 0, 0, 0]...
        [0, 0]...
      ]

      if status isnt REQUEST_STATUS.SUCCESS
        @push null
      else
        step = 'ignore'
        @emit 'success'

  return handler

exports[name] = value for name, value of (require './const')
