exports.VERSION = 0x04

exports.COMMAND =
  CONNECT: 0x01
  BIND: 0x02

exports.REQUEST_STATUS =
  GRANTED: 0x5a
  FAILED: 0x5b
  REFUSED: 0x5b # same as FAILED
  IDENTD_FAILED: 0x5c
  WRONG_USERID: 0x5d

exports.RSV = 0x00
