uri = URI.parse(ENV["NEO4J_URL"])
# these are the default values:
Neography.configure do |config|
  config.protocol       = "http://"
  config.server         = uri.host
  config.port           = uri.port
  config.directory      = ""  # prefix this path with '/'
  config.cypher_path    = "/cypher"
  config.gremlin_path   = "/ext/GremlinPlugin/graphdb/execute_script"
  config.log_file       = "neography.log"
  config.log_enabled    = false
  config.max_threads    = 20
  config.authentication = nil  # 'basic' or 'digest'
  config.username       = uri.user
  config.password       = uri.password
  config.parser         = MultiJsonParser
end

#$neo = Neography::Rest.new