FastGettext.add_text_domain 'gor', :path => 'locale', :type => :po
FastGettext.default_available_locales = ['es','pt','en','fr'] #all you want to allow
FastGettext.default_text_domain = 'gor'

# configure default msgmerge parameters (the default contains "--no-location" option
# which removes code lines from the final POT file)
Rails.application.config.gettext_i18n_rails.msgmerge = ["--sort-output", "--no-wrap"]

# enable fallback handling
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)
 
# set some locale fallbacks needed for ActiveRecord translations
# located in rails_i18n gem (e.g. there is en-US.yml translation)
I18n.fallbacks[:"en_US"] = [:"en-US", :en]
I18n.fallbacks[:"en_GB"] = [:"en-GB", :en]
I18n.fallbacks[:"pt_BR"] = [:"pt-BR", :pt]
I18n.fallbacks[:"es_ES"] = [:"es-ES", :es]
I18n.fallbacks[:"fr_FR"] = [:"fr-FR", :fr]
