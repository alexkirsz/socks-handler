ip = require 'ip'
{ VERSION, AUTH_METHOD, COMMAND, AUTH_STATUS, ADDRTYPE, REQUEST_STATUS, RSV } = require './const'

exports.handshake = (data) ->
  if data.length < 3
    throw new Error 'Invalid handshake data'

  version = data[0]
  if version isnt VERSION
    throw new Error "Wrong SOCKS version: #{version}, expected #{VERSION}"

  nmethods = data[1]
  if data.length isnt (2 + nmethods) or nmethods is 0
    throw new Error 'Invalid handshake data'

  methods = Array::slice.call data[2...2 + nmethods]

  for method in methods when method not in [AUTH_METHOD.NOAUTH, AUTH_METHOD.USERNAME_PASSWORD]
    throw new Error "Unsupported authentication method: #{method}"

  return { version, methods }

exports.auth = (data, method) ->
  switch method
    when AUTH_METHOD.USERNAME_PASSWORD
      if data.length < 5
        throw new Error 'Invalid auth data'

      version = data[0]
      if version isnt VERSION
        throw new Error "Wrong SOCKS version: #{version}, expected #{VERSION}"

      ulength = data[1]

      if data.length < 4 + ulength or ulength is 0
        throw new Error 'Invalid auth data'

      username = data[2...2 + ulength].toString()
      plength = data[2 + ulength]

      if data.length < 3 + ulength + plength or plength is 0
        throw new Error 'Invalid auth data'

      password = data[3 + ulength...3 + ulength + plength].toString()

      return { username, password }

    else throw new Error "Unsupported authentication method: #{method}"

exports.request = (data) ->
  if data.length < 10
    throw new Error 'Invalid request data'

  version = data[0]
  if version isnt VERSION
    throw new Error "Wrong SOCKS version: #{version}, expected #{VERSION}"

  command = data[1]
  rsv = data[2]

  addrType = data[3]
  if addrType not in [ADDRTYPE.IPV4, ADDRTYPE.IPV6, ADDRTYPE.DOMAIN]
    throw new Error "Invalid address type: #{addrType}"

  switch addrType
    when ADDRTYPE.IPV4
      if data.length isnt 10
        throw new Error 'Invalid request data'

      hostBuffer = data[4...8]
      host = ip.toString hostBuffer
      portBuffer = data[8...10]
      port = portBuffer.readUInt16BE 0

    when ADDRTYPE.IPV6
      if data.length isnt 22
        throw new Error 'Invalid request data'

      hostBuffer = data[4...20]
      host = ip.toString hostBuffer
      portBuffer = data[20...22]
      port = portBuffer.readUInt16BE 0

    when ADDRTYPE.DOMAIN
      length = data[4]
      if data.length isnt 7 + length
        throw new Error 'Invalid request data'

      hostBuffer = data[5...5 + length]
      host = hostBuffer.toString 'ascii'
      portBuffer = data[5 + length...7 + length]
      port = portBuffer.readUInt16BE 0

  return { version, command, addrType, hostBuffer, portBuffer, host, port }
