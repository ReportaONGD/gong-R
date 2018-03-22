$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "webservice/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = Webservice::NAME 
  s.version     = Webservice::VERSION
  s.authors     = ["Santiago Ramos (Semilla de Software Libre)"]
  s.email       = ["Santiago Ramos <sramos@semillasl.com>"]
  s.homepage    = "https://gong.org.es/projects/gongr"
  s.summary     = Webservice::SUMMARY 
  s.description = Webservice::DESCRIPTION 

  s.files = Dir["{app,config,db,lib}/**/*"] + ["COPYING", "AUTHORS", "changelog", "Rakefile", "README.rdoc"]
  #s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.9"
  # s.add_dependency "jquery-rails"

  #s.add_development_dependency "sqlite3"
  s.add_dependency 'rabl'
  s.add_dependency 'oj'
  s.add_dependency 'swagger-blocks'
  s.add_dependency 'rack-cors'
end
