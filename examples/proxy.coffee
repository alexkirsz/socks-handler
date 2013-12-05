net = require 'net'
socks = require '../src'

server = net.createServer (clientConnection) ->
  clientConnection.on 'error', (err) ->
    console.log 'clientConnection', err

  socks.handle clientConnection,
    request: ({ version, command, host, port }, callback) ->
      if command isnt socks[5].COMMAND.CONNECT
        if version is 5
          callback socks[5].REQUEST_STATUS.COMMAND_NOT_SUPPORTED
        else
          callback socks[4].REQUEST_STATUS.REFUSED
        return

      serverConnection = net.createConnection port, host

      clientConnection.pipe(serverConnection).pipe(clientConnection)

      serverConnection
        .on 'error', onConnectError = (err) ->
          if version is 5
            status =
              switch err.code
                when 'EHOSTUNREACH' then socks[5].REQUEST_STATUS.HOST_UNREACHABLE
                when 'ECONNREFUSED' then socks[5].REQUEST_STATUS.CONNECTION_REFUSED
                when 'ENETUNREACH' then socks[5].REQUEST_STATUS.NETWORK_UNREACHABLE
                else socks[5].REQUEST_STATUS.SERVER_FAILURE
          else
            status = socks[4].REQUEST_STATUS.FAILED

          callback status

        .on 'connect', ->
          serverConnection.removeListener 'error', onConnectError
          status = if version is 5 then socks[5].REQUEST_STATUS.SUCCESS else socks[4].REQUEST_STATUS.GRANTED
          callback status

        .on 'error', (err) ->
          console.log 'serverConnection', err, host, port

  , (err) ->
    console.log 'handler', err

server.listen 1080
