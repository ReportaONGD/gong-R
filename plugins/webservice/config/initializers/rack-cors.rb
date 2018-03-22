# config/initializers/rabl.rb
#
# Con esto deberia bastar y no haria falta meter rabl en el Gemfile de GONG 
# sin embargo no funciona la solucion de https://github.com/nesquena/rabl/wiki/Setup-rabl-with-rails-engines
#
require 'rack'
require 'rack/cors'

	Rails.application.config.middleware.use "Rack::Cors" do
	  allow do
	    origins '*'
	    resource '*', :headers => :any, :methods => [:get, :post, :delete, :put, :options]
  end
end