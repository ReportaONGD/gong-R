require 'rubygems'
require 'mysql2'
require 'yaml'

config = YAML::load_file("C:/Proyectos/Gong-R/SRC/gong-gor-2.54/config/database.yml")["production"]
config["host"] = config["hostname"]
puts config.to_yaml

client = Mysql2::Client.new(config)
