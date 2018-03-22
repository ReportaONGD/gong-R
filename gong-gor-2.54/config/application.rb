require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Gor
  class Application < Rails::Application

    # Schema in sql format (db/structure.sql)
    # config.active_record.schema_format = :sql

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    # ... para lib/user_info.rb y asi poder conocer desde los modelos el usuario autentificado
    config.autoload_paths += Dir["#{config.root}/lib"]
    # ... para poder implementar los concerns de modelos
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    # ... para poder implementar los concerns de controladores
    #config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false
    config.i18n.default_locale = :es

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    #config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Evitamos que se inicialice al precompilar los assets (no depender del database.yml)
    #config.assets.initialize_on_precompile = false

    # PDFKit
    #require 'pdfkit'
    #config.middleware.use PDFKit::Middleware
    # SHRIMP
    #require 'shrimp'
    #config.middleware.use Shrimp::Middleware
    # Incluimos el protocolo, host y puerto en el asset host para que pdfkit lea los css
    config.action_controller.asset_host = Proc.new { |source, request=nil|
      "#{request.protocol}#{request.host_with_port}" if request
    }

    # Ubicacion por defecto de los plugins
    ENV['GOR_PLUGINS'] ||= "/usr/share/gong/plugins"

    #
    # Configura los paths para multisitio. Con la variable de entorno GOR_SITEID se
    # define los paths particulares de una instancia concreta.
    # En apache se define a traves de la directiva:
    #         SetEnv GOR_SITEID "nombre_instancia"
    #
    ENV['RAILS_ETC'] ||= "/etc/gong/#{ENV['GOR_SITEID']}"
    ENV['RAILS_LOG'] ||= "/var/log/gong/"
    ENV['RAILS_VAR'] ||= ENV['GOR_SITEID']? "/var/lib/gong/#{ENV['GOR_SITEID']}/" : Rails.root.to_s + "/files/"
    ENV['TMPDIR'] ||= ENV['GOR_SITEID']? "/tmp/gong_#{ENV['GOR_SITEID']}/" : Rails.root.to_s + "/tmp/"
    ENV['RAILS_CACHE'] ||= "/var/cache/gong/#{ENV['GOR_SITEID']}"
    # Esto podría ir en el controlador cuadrodemando, pero lo dejamos aqui de momento para pruebas
    # para dejar el correcto (http://localhost:8080/), comentar la siguiente línea
    #ENV['GONG_CM_URL'] = 'http://desarrollo.gong.org.es:8080/'

    # Si estamos en un multisite
    if ENV['GOR_SITEID']
      # Configura la BBDD a usar, logs y directorio de cache
      self.paths['config/database'] = ENV['RAILS_ETC'] + '.database.yml'
      config.logger = ActiveSupport::BufferedLogger.new(File.join(ENV['RAILS_LOG'], ENV['GOR_SITEID'] + "." + ENV['RAILS_ENV'] + ".log"))
      # Si no existe, genera el directorio temporal
      Dir.mkdir(ENV['TMPDIR']) unless File.directory?(ENV['TMPDIR'])
      # Si no existe, genera el directorio de cache
      Dir.mkdir(ENV['RAILS_CACHE']) unless File.directory?(ENV['RAILS_CACHE'])
      # Y lo utiliza
      config.cache_store = [ :file_store, ENV['RAILS_CACHE'] ]
      config.assets.cache_store = [ :file_store, ENV['RAILS_CACHE'] + "/assets" ]
    end

    #
    # Obtiene la version para mostrarla en el header de la pagina
    #
    File.open(Rails.root.to_s + "/changelog", "r") do |fichero|
      while (linea=fichero.gets) && ENV['GOR_VERSION'].nil?
        linea =~ /^\s*(\S+).+Version\s+(.+)$/
        ENV['GOR_VERSION'] = $2 + " (" + $1 + ")" if $1 && $2
      end
    end if File.exists?(Rails.root.to_s + "/changelog")
    ENV['GOR_VERSION'] ||= "desconocida"

    # Configuracion inicial del calendar
    CalendarDateSelect.format = :italian
    CalendarDateSelect::FORMATS[:italian] = {
      # Here's the code to pass to Date#strftime
      :date => "%m/%d/%Y",
      :time => " %I:%M %p",  # notice the space before time.  If you want date and time to be seperated with a space, put the leading space here.
      :javascript_include => "format_italian"
    }

    # Selecciona el path donde estara el logo de la ONG
    if ENV['GOR_SITEID'] && File.file?(ENV['RAILS_VAR'] + "logo/" + ENV['GOR_SITEID'] + ".png")
      config.middleware.use Rack::Static, :urls => [ '/logo' ], :root => ENV['RAILS_VAR']
      ENV['GOR_LOGO'] = "/logo/" + ENV['GOR_SITEID'] + ".png"
    else
      ENV['GOR_LOGO'] = "/images/logo_gong_2.png"
    end

  end
end