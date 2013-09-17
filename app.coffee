#!/usr/local/share/npm/bin/coffee
fs = require 'fs'
csv = require 'csv'
_ = require 'underscore'
coffee = require 'coffee-script'
through = require 'through'
browserify = require 'browserify'
{minify} = require 'uglify-js'


DUMP_FILE = './tmp/dump'
REQUIRES_BLOCK = "$ = require('../vendor/jquery.js'); require('../vendor/jquery.cookie.js');"

rowToJson = (headers, row) -> _.object headers, row

jsonData = (csvData) ->
  csvData = _.clone(csvData)
  headers = csvData.shift() # remove headers
  csvData.map (row) -> rowToJson(headers, row)

createDump = (csvData) ->
  dump = jsonData(csvData).map (row) ->
    "$.cookie('#{row.Name}', '#{row.Value}', {domain: '#{row.Domain}', path: '#{row.Path}', secure: #{!!row.Secure}})"

  REQUIRES_BLOCK + "$.cookie.raw = true;" + dump.join(';') + ';'

# 'Name'
# 'Value'
# 'Domain'
# 'Path'
# 'Expires / Max-Age'
# 'Size'
# 'HTTP'
# 'Secure'

input = fs.readFileSync('/dev/stdin').toString()

csv().from.string(input).to.array (data) ->
  if !!~process.argv.indexOf('-d')
    process.stdout.write _.chain(jsonData(data)).pluck('Domain').uniq().value().join("\n") + "\n"
    process.exit(0)

  fs.writeFileSync(DUMP_FILE, createDump(data))
  b = browserify()
  b.add(DUMP_FILE)
  s = b.bundle()
  s.resume()
  string = ''
  s.on 'data', (data) -> string += data
  s.on 'end', ->
    process.stdout.write minify(string, fromString: true).code
    process.exit(0)
