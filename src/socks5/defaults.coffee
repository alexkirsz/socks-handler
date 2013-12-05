{ AUTH_METHOD, AUTH_STATUS, REQUEST_STATUS } = require './const'

exports.handshake = ({ methods }, callback) ->
  if AUTH_METHOD.NOAUTH in methods
    callback AUTH_METHOD.NOAUTH
  else
    callback AUTH_METHOD.NO_ACCEPTABLE_METHOD

exports.auth = (infos, callback) ->
  callback AUTH_STATUS.FAILURE

exports.request = (infos, callback) ->
  callback REQUEST_STATUS.SERVER_FAILURE
