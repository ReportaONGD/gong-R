# encoding: UTF-8

TEXTOS_AYUDA = YAML.load_file(Rails.root.join('config/textos_ayuda.yml'))
TEXTOS_AYUDA_PT = YAML.load_file(Rails.root.join('config/textos_ayuda.pt.yml'))
TEXTOS_AYUDA_EN = YAML.load_file(Rails.root.join('config/textos_ayuda.en.yml'))


def texto_ayuda seccion, controlador=nil, accion=nil
  #puts "------------------------> Buscando seccion: " + (params[:seccion] || "nil") + " controlador: " + (params[:controller] || "nil") + " accion: " + (params[:action]||"nil")
  texto = Array.new
  textos_ayuda = case session[:idioma_seleccionado]
    when "pt" then TEXTOS_AYUDA_PT
    when "en" then TEXTOS_AYUDA_EN
    else TEXTOS_AYUDA
  end
 
  if textos_ayuda['secciones'][seccion]
    texto.push(textos_ayuda['secciones'][seccion]['info']) if textos_ayuda['secciones'][seccion]['info']
    texto.push("<a href='" + textos_ayuda['secciones'][seccion]['url'] + "' target='_blank'>"+ _("Más info...") + "</a>") if textos_ayuda['secciones'][seccion]['url']
    if controlador && textos_ayuda['secciones'][seccion]['controladores'] && textos_ayuda['secciones'][seccion]['controladores'][controlador] 
      texto.push(textos_ayuda['secciones'][seccion]['controladores'][controlador]['info']) if textos_ayuda['secciones'][seccion]['controladores'][controlador]['info']
      texto.push("<a href='" + textos_ayuda['secciones'][seccion]['controladores'][controlador]['url'] + "' target='_blank'>"+ _("Más info...") + "</a>") if  textos_ayuda['secciones'][seccion]['controladores'][controlador]['url']
      if accion && textos_ayuda['secciones'][seccion]['controladores'][controlador]['acciones'] && textos_ayuda['secciones'][seccion]['controladores'][controlador]['acciones'][accion]
        texto.push(textos_ayuda['secciones'][seccion]['controladores'][controlador]['acciones'][accion]['rotulo'])
        texto.push(textos_ayuda['secciones'][seccion]['controladores'][controlador]['acciones'][accion]['info'])
        texto.push("<a href='" + textos_ayuda['secciones'][seccion]['controladores'][controlador]['acciones'][accion]['url'] + "' target='_blank'>"+ _("Más info...") + "</a>") if textos_ayuda['secciones'][seccion]['controladores'][controlador]['acciones'][accion]['url']
      end
    end
  end
  #puts "--------------> " + texto.inspect
  return texto
end

