ip = require 'ip'
{ VERSION } = require './const'

readString = (data, offset) ->
  i = offset
  i++ while data[i] and data[i] isnt 0x00
  return data[offset...i].toString()

exports.request = (data) ->
  if data.length < 9
    throw new Error 'Invalid request data'

  version = data[0]
  if version isnt VERSION
    throw new Error "Wrong SOCKS version: #{version}, expected #{VERSION}"

  command = data[1]
  portBuffer = data[2...4]
  port = portBuffer.readUInt16BE 0
  hostBuffer = data[4...8]
  host = ip.toString hostBuffer

  if hostBuffer[0] is hostBuffer[1] is hostBuffer[2] is 0
    # SOCKS 4a
    userID = readString data, 8
    host = readString data, 9 + userID.length
  else
    userID = readString data, 8

  return { version, command, portBuffer, port, hostBuffer, host, userID }
