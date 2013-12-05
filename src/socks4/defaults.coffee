{ REQUEST_STATUS } = require './const'

exports.request = (infos, callback) ->
  callback REQUEST_STATUS.FAILED
