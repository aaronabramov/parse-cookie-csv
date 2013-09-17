fs = require "fs"
csv = require "csv"
_ = require "underscore"


rowToJson = (headers, row) ->
  _.object headers, row

jsonData = (csvData) ->
  csvData = _.clone(csvData)
  headers = csvData.shift() # remove headers
  csvData.map (row) -> rowToJson(headers, row)

createDump = (csvData) ->
  dump = jsonData(csvData).map (row) ->
    "$.cookie('#{row.Name}', '#{row.Value}', {domain: '#{row.Domain}', path: '#{row.Path}', secure: #{!!row.Secure}})"

  "$.cookie.raw = true;" + dump.join(';') + ';'

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

  process.stdout.write createDump(data)