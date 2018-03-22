
    # NOTA: Esto hay que ponerlo en un initializer con este nombre para que se cargue despues del de fast_gettext y asi evitar
    #       un error de tipo: Current textdomain ("app") was not added, use FastGettext.add_text_domain ! (FastGettext::Storage::NoTextDomainConfigured)

    # Definimos la variable inicial para recoger modulos de autentificaciones externas
    Gor::Application.config.external_auth = []
    # Lo metemos en un try/catch para evitar errores si no exite el modelo Plugin
    begin
      Plugin.search_external_auth
    rescue Exception => e
      Rails.logger.info "----> (inicializando auth externa): " + e.inspect
    end

