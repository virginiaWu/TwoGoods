fs = require 'fs'
exec = (require 'child_process').exec
path = require 'path'

utils = require './common/utils'
promiseWhile = utils.promiseWhile

es_client = (require './es_client').es_client

pingEs = ->
  console.log 'Ping...'
  ready = false
  promiseWhile ->
    return not ready
  , ->
    es_client.ping
      hello: "elasticsearch"
    .then ->
      console.log 'Ping successfully...'
      ready = true
    .catch ->
      console.log 'Ping failed...'
      ready = false 
    .delay 500

getDBVersion = ->
  es_client.getSource
    index: 'version'
    type: 'ver'
    id: 'v'
  .then (ver) ->
    doc:
      version: ver.version
  .catch (err) ->
    es_client.index
      index: 'version'
      type: 'ver'
      id: 'v'
      timestamp: new Date()
      body:
        version: 0
    .then ->
      doc:
        version: 0

#TODO: set the `coffee` env
getUpdateCmd = ->
  if fs.existsSync "#{__dirname}/update/update.js"
    targetPath = path.resolve "#{__dirname}/../es/update/update.js"
    return "node #{targetPath}"
  targetPath = path.resolve "#{__dirname}/../es/update/update.coffee"
  coffeePath = path.resolve "#{__dirname}/../node_modules/.bin/coffee"
  "#{coffeePath} #{targetPath}"

updateDBVersion = (cb) ->
  updateCmd = getUpdateCmd()
  exec updateCmd, (err, stdout, stderr) ->
    console.log 'updateDBVersion err', err
    console.log 'updateDBVersion stdout', stdout
    console.log 'updateDBVersion stderr', stderr
    cb()

module.exports =
  pingEs: pingEs
  getDBVersion: getDBVersion
  getUpdateCmd: getUpdateCmd
  updateDBVersion: updateDBVersion
