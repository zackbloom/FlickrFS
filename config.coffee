fs = require('fs')
yaml = require('js-yaml')

load = (path) ->
  try
    fs.statSync(path)
  catch e
    if e.code is 'ENOENT'
      return null
    else
      throw e

  return require(path)

save = (path, config) ->
  str = yaml.dump(config)
  fs.writeFileSync(path, str)

module.exports = {load, save}
