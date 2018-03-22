namespace :gettext do
  # Añadimos las direcciones de los plugins para su inclusion en los ficheros de traduccion
  # NOTA: de momento se dejai solo  el plugin de cpt_contabilidad. Consultar el tema. 
  def files_to_translate
    gor = Dir.glob("{app,lib,config,locale}/**/*.{rb,erb,haml,slim,rhtml}")

    # Ficheros del plugin cpt_contabilidad
    plugins = Dir.glob("/usr/share/gong/plugins/cpt_contabilidad/{app,lib,config}/**/*.{rb,erb,haml,slim,rhtml}")

    # Para introducir todos los plugins descomentar esta linea
    # plugins = Dir.glob("/usr/share/gong/plugins/**/{app,lib,config}/**/*.{rb,erb,haml,slim,rhtml}")

    gor + plugins
  end
end

