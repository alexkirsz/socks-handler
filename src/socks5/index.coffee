net = require 'net'
ip = require 'ip'
through = require 'through'
parsers = require './parsers'
defaults = require './defaults'
{ VERSION, AUTH_METHOD, COMMAND, AUTH_STATUS, ADDRTYPE, REQUEST_STATUS, RSV } = require './const'

exports.createHandler = (_handlers) ->
  step = 'handshake'
  authMethod = -1

  handlers = {}
  handlers[name] = value for name, value of defaults
  handlers[name] = value for name, value of _handlers

  onwrite = (chunk) ->
    switch step
      when 'handshake' then handshake.call @, chunk
      when 'authentication' then authentication.call @, chunk
      when 'request' then request.call @, chunk

  handshake = (data) ->
    try
      handshake = parsers.handshake data
    catch e
      @emit 'error', e

    handlers.handshake handshake, (method) =>
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

    handlers.auth auth, (status) =>
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

    handlers.request request, (status, localPort, localAddress) =>
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

  through onwrite

exports[name] = value for name, value of (require './const')
