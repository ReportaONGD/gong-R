# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Gor::Application.initialize!

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Evitamos errores por Mysql 5.7.9
# Mysql2::Error: All parts of a PRIMARY KEY must be NOT NULL; if you need NULL in a key, use UNIQUE instead
# http://stackoverflow.com/questions/33755062/mysql-5-7-9-rails-3-2-mysql2-0-3-20
class ActiveRecord::ConnectionAdapters::Mysql2Adapter
  NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
end
