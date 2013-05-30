fs = require('fs')
_ = require('underscore')
program = require('commander')
  .version('0.0.1')
  .option('-m, --mount', 'Mount point', './mnt')
  .option('-c, --config', 'Configuration file location [./fs-flickr.yaml]')
  .parse(process.argv)

program.config ?= './fs-flickr.yaml'

config = require('./config')
auth = require('./auth')
ffs = require('./ffs')

opts = config.load program.config
_.extend opts, program
console.log opts

if not opts.ACCESS_TOKEN? or not opts.ACCESS_SECRET?
  auth opts, (err, accessToken, accessSecret) ->
    return if err

    opts.ACCESS_TOKEN = accessToken
    opts.ACCESS_SECRET = accessSecret

    ffs.start(opts)
else
  ffs.start(opts)
