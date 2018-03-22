# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2013 Free Software's Seed, CENATIC y IEPALA
#
# Licencia con arreglo a la EUPL, Versión 1.1 o –en cuanto sean aprobadas por la Comisión Europea– 
# versiones posteriores de la EUPL (la «Licencia»);
# Solo podrá usarse esta obra si se respeta la Licencia.
# Puede obtenerse una copia de la Licencia en:
#
# http://www.osor.eu/eupl/european-union-public-licence-eupl-v.1.1
#
# Salvo cuando lo exija la legislación aplicable o se acuerde por escrito, 
# el programa distribuido con arreglo a la Licencia se distribuye «TAL CUAL»,
# SIN GARANTÍAS NI CONDICIONES DE NINGÚN TIPO, ni expresas ni implícitas.
# Véase la Licencia en el idioma concreto que rige los permisos y limitaciones que establece la Licencia.
#################################################################################
#
#++
# metodos utilizados en todas las "views"

#--
# ABORRAR: 27 de abril de 2010
#++
module ApplicationHelper

  #--
  # METODOS GENERALES
  #++

  # helper de generacion de iconos con image_tag
  def icono tipo, *rotulo
    image_tag("/images/iconos_bn/" + tipo + ".png", :border => 0, :id => rotulo[1], :class => "icono", :title => rotulo[0] || "", :onmouseover => "this.src='/images/iconos_bn/" + tipo + "_s.png';", :onmouseout => "this.src='/images/iconos_bn/" + tipo + ".png';" )
  end


  #--
  # METODOS DE  FORMULARIO
  #++

  # ajax true o false para form_remote_tag o form_tag
  def comienzo_formulario url, ajax=false, otros={}
    id_formulario = otros[:id]||"formulario"
    if ajax
      cadena = form_remote_tag( :url => url, :html => {:id => id_formulario, :class => "formulario"}, :multipart => true, :before => "tinyMCE.triggerSave(true, true);", :loading => "Element.show('spinner'); Element.hide('botonguardar');", :complete => "Element.hide('spinner')")
    else
      #cadena = form_tag( url, :multipart => true, :class => "formulario", "data-confirm" => "Sure?" )
      cadena = form_tag( url, :multipart => true, :class => "formulario", :id => id_formulario )
    end
    cadena << "<div id='mensaje_formulario'></div>".html_safe
    cadena << "<div class='fila' id='spinner' style='display:none'></div>".html_safe
    cadena << "<div class='fila'></div>".html_safe
    return cadena
  end



  # submit_tag con botón guardar
  def final_formulario boton={}
    cadena = '<div class="fila" id="botonguardar" > <div class="elementoderecha">'.html_safe
    #cadena << submit_tag((boton[:texto_alternatif] || "Guardar"), :class => "boton", :onclick => "this.disabled=true; return true;")
    if boton[:confirmar]
      cadena << boton_confirmar( :enlace => (boton[:texto_alternatif] || _("Guardar")), :identificador => "send_form", :texto => boton[:confirmar])
    else
      cadena << submit_tag((boton[:texto_alternatif] || _("Guardar")), :class => "boton", "data-disable-with" => _("Enviando..."))
    end
    cadena << "</div></div>".html_safe
    cadena << "</FORM>".html_safe
    # Enriquece los selectores chosen
    cadena << javascript_tag("activaSelectoresChosen();")
  end

  def etiqueta rotulo, clase="1"
    return ("<div class='elemento" + clase + "' title='" + h(rotulo) + "'><span>" + h(rotulo) + "</span></div>").html_safe
  end

  # A FUSIONAR CON "TEXTO" text_field para colocarle un rotulo e incluirlo en un div con la clase, y le pone como clase al campo texto "textonumero".
  def texto_numero rotulo , objeto, atributo, clase, otros={}
    clase_rotulo = otros[:obligatorio] ? "obligatorio" : ""
    cadena = ("<div class='elemento_formulario elemento" + clase + "'>").html_safe
    cadena += ("<span id='rotulo_" + objeto + "_" + atributo + "' class='" + clase_rotulo + "'>" + h(rotulo) + "</span><br/>").html_safe unless rotulo.nil?
    opciones = {:class => "textonumero"+clase, :type => "d"}
    opciones[:name] = otros[:name] if otros[:name]
    opciones[:value] = otros[:value] if otros[:value]
    opciones[:disabled] = otros[:disabled] if otros[:disabled]
    opciones[:onchange] = otros[:onchange] if otros[:onchange]
    opciones[:id] = otros[:id] if otros[:id]
    if otros[:select_tag]
      cadena << text_field_tag( atributo , opciones[:value] || 0, opciones )
    else
      cadena << text_field( objeto, atributo , opciones )
    end
    return cadena << "</div>".html_safe
  end

  # text_field con un rotulo e incluirlo en un div con la clase.
  def texto rotulo , objeto, atributo, clase, otros={}
    opciones = {:disabled => otros[:disabled], :class => "texto" + clase}
    opciones[:value] = otros[:value] if otros[:value]
    opciones[:id] = otros[:id] if otros[:id]
    clase_rotulo = otros[:obligatorio] ? "obligatorio" : ""
    cadena = ("<div id='contenedor_" + objeto + "_" + atributo + "' class='elemento_formulario elemento"+ clase +"'>").html_safe
    unless rotulo.nil?
      # Permite definir una funcion javascript para la etiqueta del campo
      if otros[:label_action]
        cadena << ("<span id='rotulo_" + objeto + "_" + atributo + "' class= '" + clase_rotulo + "'>").html_safe
        cadena << link_to_function(rotulo, otros[:label_action], :title => (otros[:label_action_title] || ""))
        cadena << "</span><br/>".html_safe
      else
        cadena << ("<span id='rotulo_" + objeto + "_" + atributo + "' class='" + clase_rotulo + "'>").html_safe + rotulo + "</span><br/>".html_safe
      end
    end
    if otros[:autocomplete]
      #cadena << text_field_with_auto_complete( objeto, atributo, {:disabled => otros[:disabled], :class => "texto" + clase}, {:method => :get, :with => "'search=' + element.value", :onchange => otros[:onchange]} )
      autocomplete_with = "'search=' + element.value"
      otros[:autocomplete_with_also].each do |am|
        autocomplete_with += " + '&' + $('" + am + "').serialize()"
      end if otros[:autocomplete_with_also]
      cadena << text_field_with_auto_complete( objeto, atributo, opciones, {:method => :get, :with => autocomplete_with, :onchange => otros[:onchange], :after_update_element => otros[:after_update]} )
    else
      opciones[:type] = otros[:type]
      opciones[:name] = otros[:name]
      opciones[:onchange] = otros[:onchange]
      cadena << text_field( objeto, atributo, opciones)
    end
    return cadena << "</div>".html_safe  
  end

  # text_area con un rotulo e incluirlo en un div con la clase.
  # si la clase que se pasa es "editor_rico" incluye un Wysiwyg javascript (tyny_mce)
  def texto_area rotulo , objeto, atributo, clase, otros={}
    cadena = ""
    if clase == "editor_rico"
      #include_tiny_mce_if_needed
      cadena = "<div class=\"elemento\">".html_safe + rotulo +"<br/>".html_safe + text_area( objeto, atributo , {:disabled => otros[:disabled], :class => "tinymce mceEditor", :type => "d", :name => otros[:name]})
      cadena += tinymce_assets
      cadena += tinymce :uploadimage_hint => @proyecto.id, :language => session[:idioma_seleccionado]
    else
      cadena = ("<div class=\"elemento" + clase +"\">").html_safe + rotulo +"<br/>".html_safe + text_area( objeto, atributo , {:disabled => otros[:disabled], :class => "textoarea"+clase, :type => "d", :name => otros[:name], :rows=>2 })
    end
    return cadena << "</div>".html_safe
  end

  # password_field con un rotulo e incluido en un div con la clase (se utiliza solamente en app/views/usuario/entrada.rhtml y en app/views/usuario/_formulario.rhtml
  def contrasena rotulo , objeto, atributo, clase
    ("<div class=\"elemento"+ clase +"\">").html_safe + rotulo + "<br/>".html_safe + password_field( objeto, atributo , {:class => "texto"+clase }) + "</div>".html_safe
  end

  # select con un rotulo e incluido en un div con la clase.
  def selector rotulo , objeto, atributo, valores, vacio, clase, otros={}
    options = {:include_blank => vacio}
    options[:selected] = otros[:selected] if otros[:selected]
    clase_rotulo = otros[:obligatorio] ? "obligatorio" : ""
    html_id = otros[:id]||(objeto + "_" + atributo)
    cadena  = ("<div class='elemento_formulario elemento"+ clase +"' id='selector_" + html_id + "'>").html_safe
    cadena += ("<div id='rotulo_" + html_id + "' class='" + clase_rotulo + "'>").html_safe + rotulo + "</div>".html_safe unless rotulo.nil?
    clase += " chosen_select" if otros[:multiple] || otros[:enriquecido]
    if otros[:select_tag]
      cadena += select_tag( atributo , options_for_select(valores||[]), options.merge({:class => "selector"+clase, :multiple => otros[:multiple], :size => (otros[:size]||1), :disabled => (otros[:disabled]||false) })  ) + "</div>".html_safe
    else
      cadena += select( objeto, atributo , valores||[], options , {:class => "selector"+clase, :multiple => otros[:multiple], :name => otros[:name], :size => (otros[:size]||1), :disabled => (otros[:disabled]||false) }  ) + "</div>".html_safe
    end
  end

  # check_box 
  def checkbox rotulo, objeto, atributo, clase, otros={}
    otros[:disabled]
    title = otros[:title] ? ("title = '" + otros[:title] + "'" ) : ""
    if otros[:izquierda]
      ('<div class="elemento_formulario elemento' + clase + '" #{title}>' + ( ("<br>" if otros[:abajo]) || "")).html_safe +  check_box( objeto, atributo, {:checked => otros[:checked], :disabled => otros[:disabled]} ) + rotulo + "</div>".html_safe
    else
      ('<div class="elemento_formulario elemento' + clase + '" #{title}>' + ( ("<br>" if otros[:abajo]) || "")).html_safe + rotulo + check_box( objeto, atributo, {:checked => otros[:checked], :disabled => otros[:disabled]} ) + "</div>".html_safe
    end
  end

  # seleccionar día, mes y año (si hay en la misma pagina feche_inicio y fecha_fin, a cerrar el calendario para fecha_fin se alerta si fecha_inicio > fecha_fin)
  def calendario_fecha rotulo, objeto, atributo, otros={}
    clase_rotulo = otros[:obligatorio] ? "obligatorio" : ""
    id_elemento = otros.delete(:id)||(objeto + '_' + atributo)

    cadena  = ('<div id="contenedor_' + id_elemento + '" class="elemento_formulario elemento3_4">').html_safe
    cadena += ('<span class="' + clase_rotulo + '">' + h(rotulo) + '</span><br/>').html_safe unless rotulo.nil?

    if otros[:disabled]
      otros[:id] = id_elemento
      otros[:class] = "texto1_2"
      # Formateamos a los locales que estemos usando...
      otros[:value] = I18n.l(instance_variable_get("@#{objeto}").send(atributo)) unless instance_variable_get("@#{objeto}").nil?
      cadena += text_field(objeto, atributo, otros)
    else
      otros_hidden = {id: id_elemento}
      obj_name = otros.delete(:name)
      otros_hidden[:name] = obj_name if obj_name
      if atributo == "fecha_fin"
        otros[:after_close] = 'fecha = document.getElementById("fecha_fecha_inicio").value.match(/\d+/g); fecha_inicio = new Date( ); fecha_inicio.setFullYear(fecha[2]); fecha_inicio.setMonth(fecha[1] - 1); fecha_inicio.setDate(fecha[0]); fecha = this.value.match(/\d+/g); fecha_fin = new Date( ); fecha_fin.setFullYear(fecha[2]); fecha_fin.setMonth(fecha[1] - 1); fecha_fin.setDate(fecha[0]); if (fecha_fin < fecha_inicio) alert("Cuidado! la fecha de fin es major que la fecha de inicio")'
      end
      otros[:year_range] =  [1930, Time.now.year + 15] if  otros[:year_range].nil?
      otros[:size] = "10"
      otros[:onchange] = 'fecha = this.value.replace(/(\d+)\/(\d+)\/(\d+)/, "$3-$2-$1");  document.getElementById("' + id_elemento + '").value = fecha'
      cadena += javascript_tag( 'fecha = document.getElementById("' + id_elemento + '").value; if ( fecha ) {fecha_en_array = fecha.match(/\d+/g); ano = fecha_en_array[0]; mes = fecha_en_array[1]; dia = fecha_en_array[2]; fecha = dia + "/" + mes + "/" + ano; document.getElementById("fecha_' + id_elemento + '").value = fecha } ' )
      cadena += calendar_date_select_tag( "fecha_" + id_elemento, nil, otros) + hidden_field(objeto, atributo, otros_hidden)
    end
    cadena += "</div>".html_safe
    return cadena
  end

  # solamente para seleccionar mes y años
  def mes_fecha rotulo , objeto, atributo, otros={}
    otros[:start_year] = 1930 if not otros[:start_year]
    otros[:end_year] = Time.now.year + 10 if not otros[:end_year]
    otros[:use_month_numbers] = false if not otros[:use_month_numbers]
    otros[:order] = [:day,:month,:year] if not otros[:order]
    otros[:include_blank] = false if not otros[:include_blank]
    otros[:discard_day] = true if not (otros[:discard_day] or otros[:incluir_dia])
    ("<div class='elemento#{ otros[:class] || '1' }'>").html_safe + rotulo + '<br/>'.html_safe + date_select(objeto, atributo, otros, {:class => 'fecha' }) + '</div>'.html_safe
  end

  # solamente por seleccionar el año.
  def ejercio_fecha rotulo, id, ano_selectada, visible, otros={}
    ano = ano_selectada ? ano : Date.today
    display = visible ? "\"\"" : "none"
    ("<div id=\"" + id + "\" class=\"elemento1\" style=\"display: " + display  + "\" >").html_safe + rotulo + "<br/>".html_safe + select_year(ano, otros, {:class => "fecha"}) + "</div>".html_safe
  end   

  #-- METODOS DE  LISTADO
  #++

  # Pone la cabecera a listado siendo cabecera un array con las columnas de los elementos listados y otros los posibles campos para un icono
  # otros[0] => titulo del icono
  # otros[1] => acción del icono
  # otros[2] => id del icono
  # otros[3] => alternativa al icono anadir_relacion
  # cabecera es el array de arrray con rotulo, elemento, campo, ordenado resultado de campos_listado modelo
  def cabecera_listado cabecera, *otros
   cadena = ""
   cadena << comienzo_listado
   cadena << "<div class='filacabecera'>"
   cadena << cabecera.inject(""){|todos, e| todos + elemento_cabecera(e[0], e[1], e[2], e[3]) }
   cadena << "<div class='elementoderecha'>"
   #cadena << link_to( icono( "seleccionar", (@resumen[:mensaje] || _("Ver resumen" )) ), @resumen[:url], :popup => ['Resumen','width=1024, height=750, toolbar=no, location=yes,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes']  ) if @resumen  and (otros[0] && otros[1])
   cadena << link_to( icono( "seleccionar", (@resumen[:mensaje] || _("Ver resumen" )) ), @resumen[:url], :popup => ['Resumen','width=1024, height=750, toolbar=no, location=yes,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes']  ) if @resumen
   #cadena << link_to( icono( "descargar", _("Exportar a XLS" )), request.parameters.merge({:format => :xls, :format_xls_count => (@formato_xls.to_i+1)}) ) if @formato_xls and (otros[0] && otros[1])
   cadena << link_to( icono( "descargar", _("Exportar a XLS" )), url_for(request.parameters.merge({:format => :xls, :format_xls_count => (@formato_xls.to_i+1), :only_path => false})) ) if @formato_xls
   cadena << link_to_remote( icono("informacion", _("Información del listado")), :url => url_for(@listado_mas_info), :loading => "Element.show('espera')", :complete => "Element.hide('espera')") if @listado_mas_info
   cadena << modal( icono((otros[3] || 'anadir')), otros[1], otros[0], otros[2] || {:id => "anadir"}) if otros[0] && otros[1]
   cadena << "</div><div class='linea'></div></div>"
   return cadena.html_safe
  end


  # TODO: Rehacer el metodo para que utilice un hash y no un array en la variable otros. Implica cambiar todas las llamadas que lo utilizan
  # No es buena practica dejar codigo comentado pero antes de la versión 2.0.2 implementaremos este cambio.
  # < PROPUESTA DE NUEVO MODELO >

#  def cabecera_listado2 cabecera, icono, otros={}
#   cadena = comienzo_listado
#   cadena << "<div class='filacabecera'>\n"
#   cadena << cabecera.inject(""){|todos, e| todos + elemento_cabecera(e[0], e[1], e[2], e[3]) }
#   cadena << "<div class='elementoderecha'>\n"
#   cadena << modal( icono((otros[:icono_dos][:imagen] || 'anadir')), otros[:icono_dos][:url], otros[:icono_dos][:texto], {:id => (otros[:icono_dos][:id] || "anadir")}) if otros[:icono_dos]
#   cadena << "&nbsp;"
#   cadena << modal( icono((icono[:imagen] || 'anadir')), icono[:url], icono[:texto], {:id => (icono[:id] || "anadir")}) if icono
#   return cadena << "</div><div class='linea'></div></div>\n"
#  end

  # </ PROPUESTA DE NUEVO MODELO >



  # Dibuja cada uno de los elmentos de una cabecera.
  def elemento_cabecera rotulo, clase, atributo, ordenado
    if ordenado
      orden = ordenado.class.name == "String" ? ordenado : atributo
      #puts "-------------> " + orden.inspect + " vs. " + session["#{params[:controller]}_orden".to_sym].inspect
      if orden == session["#{params[:controller]}_orden".to_sym]
        asc_desc = session["#{params[:controller]}_asc_desc".to_sym] == "ASC" ? "DESC" : "ASC"
        icono = (asc_desc == "ASC" ?  image_tag("orden_asc.gif") : image_tag("orden_desc.gif"))
      end
      url_rotulo = {:action => :ordenado, :orden => orden, :asc_desc => asc_desc, :listado => controller.action_name}
      url_rotulo[:plugin] = params[:plugin] if params[:plugin]
      rotulo = link_to( rotulo.html_safe , url_for(url_rotulo))
    end
    return ('<div id="cabecera_' + atributo + '" class="elemento' + clase + '">' + rotulo + "  " + (icono || "") +"</div>").html_safe
  end

  # Diduja los elementos del comienzo del listado
  def comienzo_listado identado=false
    return '<div class="listado">'.html_safe unless identado
    return '<div class="listado identado_centrado">'.html_safe if identado
  end

  # Dibuja los elementos del final de un listado.
  def final_listado objetos=nil, otros={}
    if objetos && objetos.respond_to?(:total_pages)
      cadena = paginacion_sublistado objetos, session[:por_pagina], otros
    else
      cadena = "</div>".html_safe
    end
    return cadena
  end


  # Metodo que dibuja el formulario de filtrado. Parametros:
  # * El nombre de la accion de filtrado.
  # * Los rotulos del estado del filtrado.
  # * Y las opciones de filtrado.
  # NOTA: La presentacion esta pensada para que se puedan poner varias opciones de filtro.
  def formulario_filtrado url_accion, opciones_filtro
    # En lugar usar :listado dentro de url_accion y obligar a las vistas a meter de donde vienen,
    # se podria usar controller.action_name para averiguarlo automaticamente
    cadena = '<div id="aviso_formulario_filtrado" class="elementoderecha">'.html_safe
    script_ocultar = "Element.hide('formulario_filtrado');Element.hide('ocultar_filtros');Element.show('mostrar_filtros');"
    script_mostrar = "Element.show('formulario_filtrado');Element.hide('mostrar_filtros');Element.show('ocultar_filtros');"
    cadena << link_to_function( _("- ocultar filtros -"), script_ocultar.html_safe, {:id => "ocultar_filtros"} )
    cadena << link_to_function( _("- mostrar filtros -"), script_mostrar.html_safe, {:id => "mostrar_filtros", style: "display:none;"} )
    cadena << '</div>'.html_safe

    cadena << comienzo_formulario( url_accion, nil, {id: "formulario_filtrado"} )
    #cadena << '<div class="elementofiltrado"> ' + _("Filtrado") + ' &nbsp; </div> <div class="elementofiltrado">'
    #for estado in estado_filtro
    #  cadena << ' >> <i>  '+ estado +'</i><br />'
    #end
    cadena << '<div>'.html_safe
    for filtro in opciones_filtro
      valor =   session[(controller.controller_name+"_filtro_"+filtro[:nombre]).to_sym] 
      case filtro[:tipo]
      when "calendario" 
        # Para el filtrado de calendario guardamos
        cadena << mes_fecha(filtro[:rotulo] , 'filtro',filtro[:nombre], :default => valor, :incluir_dia => true, :class=> "1y1_4")
        #cadena <<  "<div class=\"elemento3_4\">" + filtro[:rotulo] +"<br/><div class=\"calendario_pie\">"+ calendar_date_select_tag( "filtro[#{filtro[:nombre]}]", valor, :size => 13, :class => "fecha") + "</div></div>"
      when "autocompletado"
        clase = (filtro[:clase]||"3_2") + " filtro"
        cadena << texto(filtro[:rotulo] , 'filtro',filtro[:nombre], clase, :autocomplete => true, valor => "pepe")
      when "checkbox"
        clase = (filtro[:clase]||"1_2") + " filtro"
        cadena << checkbox(filtro[:rotulo] , 'filtro',filtro[:nombre], clase, :checked => valor, :abajo => true)
      when "texto"
        clase = (filtro[:clase]||"3_4") + " filtro"
        cadena << texto(filtro[:rotulo] , 'filtro',filtro[:nombre], clase, :value => valor)
      when "multiple"
        clase = (filtro[:clase]||"3_4") + " filtro"
        cadena << selector( filtro[:rotulo], 'filtro', filtro[:nombre], filtro[:opciones], false, clase, {selected: valor, multiple: filtro[:tipo]})
      else
        clase = (filtro[:clase]||"3_4") + " filtro"
        cadena << selector( filtro[:rotulo], 'filtro', filtro[:nombre], filtro[:opciones], false, clase, {:selected => valor, enriquecido: filtro[:enriquecido]})
      end
    end
    cadena << '<div class="elementoderecha">'.html_safe  + submit_tag(_("Filtrar"), :class => "boton1_2") + '</div>'.html_safe
    cadena << '</div></form>'.html_safe
    cadena << '<div class="linea"></div>'.html_safe
    return cadena
  end

  def comienzo_sublistado rotulo, sub_id, otros={}
      sub_id ||= "sublistado"
      script = "document.getElementById('" +  sub_id + "').innerHTML=\"\";"
      cadena = '<fieldset class="sublistado" id = "'+ sub_id +'_sublistado" ><div class="legend">'+ h(rotulo) +'</div>'
      if otros[:campos_listado]
        cadena << '<div class="linea filacabecera">'
        cadena << otros[:campos_listado].inject(""){|todos, e| todos + h(elemento_cabecera(e[0], e[1], e[2], e[3])) }
      else
        cadena << '<div class="linea">'
      end
      cadena << '<div class="elementoderecha" id="cerrarsublistado">'
      cadena << anadir( :url => otros[:anadir][:url] ) if otros[:anadir]
      #cadena << modal( icono("anadir"), otros[:anadir][:url], h(otros[:anadir][:mensaje] || "Añadir " + rotulo)) if otros[:anadir]
      if @formato_xls && otros[:descargar]
        params_xls = request.parameters.merge({:format => :xls, :format_xls_count => (@formato_xls.to_i+1)})
        params_xls.merge!(otros[:descargar]) if otros[:descargar].class.name == "Hash"
        cadena << link_to( icono( "descargar", _("Exportar a XLS" )), params_xls )
      end
      cadena << link_to( icono( "descargar", _("Exportar a PDF" )), request.parameters.merge({format: :pdf}) ) if otros[:descargar_pdf]
      cadena << remote( icono("informacion", _("Información del listado")), :url => url_for(@listado_mas_info), :html => {:id => "mas_info_listado"}) if @listado_mas_info
      cadena << link_to_function( icono( "cerrar", "Ocultar sublistado"), script, {:id => sub_id + "_ocultar_sublistado"} ) unless otros[:no_cerrar]
      cadena << '</div></div>'
      return cadena.html_safe
  end

  # Dibuja los elementos del final del sublistado.
  def final_sublistado objetos=nil, otros={}
    cadena = ""
    if objetos && objetos.respond_to?(:total_pages)
      cadena = paginacion_sublistado objetos, session[:por_pagina], otros
    end
    return cadena.html_safe + "</fieldset>".html_safe
  end

  # dibuja cada fila del listado
  def fila_listado objeto, campos, id, campos_info = nil
    #return campos.inject(""){|todos, e| todos + elemento_listado(objeto, e[2], e[1], e[2], id)}
    #ventana_info_popup transferencia, {:campos => campos_listado("transferencia") + campos_info("transferencia"), :id => update + "_informacion" }
    elementos = campos.inject(""){|todos, e| todos + elemento_listado(objeto, e[2], e[1], e[2], id)}
    return elementos.html_safe unless campos_info
    return ventana_info_popup objeto, {:campos => campos_info, :id => id + "_valores_informacion", :fila => elementos} if campos_info
  end

  def comienzo_fila_listado objeto, otros={}
    # Si no existe, le pone un id automatico
    otros[:id] ||= "fila_" + objeto.class.name.downcase + "_" + (objeto.id||"nuevo").to_s
    # Rellena la clase si está vacía
    otros[:class] ||= ""
    # Deja vacios los campos si no estan definidos
    otros[:campos] ||= [] 
    cadena = '<div id="' + otros[:id].to_s + '" class="fila ' + otros[:class].to_s + '">'
    elementos = otros[:campos].inject(""){|todos, e| todos + elemento_listado(objeto, e[2], e[1], e[2], otros[:id])}
    cadena += elementos unless otros[:campos_info]
    cadena += ventana_info_popup(objeto, otros.merge(campos: otros[:campos_info], fila: elementos)) if otros[:campos_info]
    return cadena.html_safe
  end

  # Caracteres que pueden tener cada uno de los anchos de los elementos de los listados
  # La nomenclatura es como sigue:
  # La clave de la Hash 1, 2, 3,... hace referencia al elemento1, elemento2,... al que le corresponde un estilo determinado en el css.
  # Y el valor al que va asociado es el numero de caracteres para el ancho de ese tipo de elemento.
  # Ejemplo: el elemento1 (que son 250px) caben 32 caracteres.
  CARACTERES = { "9_2" => 142, "4" => 128, "3" => 87, "5_2" => 74,
                 "2" => 64, "3_2" => 40, "5_4" => 34, "1"  => 28,
                 "3_4" => 21, "1_2" => 13, "1_3" => 11,
                 "1_4"=> 10 , "1_8" => 5 }
  def caracteres tipo
    return CARACTERES[tipo.split("_td")[0]]||28
  end

  # dibuja cada elemento del listado  
  def elemento_listado objeto, campo, clase, nombre, id
    begin
      #guardamos el objeto para ahcer otras llamadas
      objeto_inicial = objeto
      #campo.split('.').each { |metodo| objeto = objeto.send(metodo)}
      campo.split('.').each { |metodo| objeto = (metodo =~ /(\S+)\s(\S+)/ ? objeto.send($1,$2) : objeto.send(metodo)) }
      case campo
        when "importe", "gasto.importe", "gasto_x_proyecto.first.importe", "suma_presupuesto", "presupuesto_x_actividad.first.importe", "importe_enviado", "importe_cambiado"
          then cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">"+ float_a_moneda(objeto) + "</div>"
        when /fecha/
          then cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">"+( objeto.strftime('%d/%m/%Y') )   +"</div>"
        when "rol.capitalize", "tipo.capitalize", "transferencia.first.tipo.capitalize", "tipo_asociado.capitalize", "tipo_mayusculas", "tipo"
          then cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">" + _(objeto) + "</div>"
        when "realizada", "estado_actual.realizada"
          then cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">"+( objeto ? _("Cerrada") : _("En curso") )   +"</div>"
        # A la tasa de cambio le damos un tratamiento especial para que incluya 5 decimales
        when "tasa_cambio", "salario_hora"
          then cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\" title='"+h(objeto.to_s)+"'>" +( objeto && objeto.to_s != "" ? truncate(h(format("%.5f",objeto)), :length => ( CARACTERES[clase] || 15 )) : "&nbsp;")   +"</div>"
        when "porcentaje", "porcentaje_actual", /^porcentaje_x_proyecto/
          then cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">" + caja_porcentaje(:total => 1, :valor => objeto) + "</div>"
        when "porcentaje_tiempo"
          then cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">" + caja_porcentaje(:total => 1, :valor => objeto, :rotulo => objeto_inicial.send(campo +"_rotulo")) + "</div>"
        when "porcentaje_tareas_configuracion", "porcentaje_periodo_formulacion", "porcentaje_periodo_seguimiento_oficial", "porcentaje_periodo_seguimiento_interno", "implantacion_configuracion", "implantacion_periodos", "implantacion_formulacion", "implantacion_seguimiento", "porcentaje_objetivos_resultados_con_indicadores", "porcentaje_objetivos_resultados_con_fverificacion", "porcentaje_resultados_con_actividades", "porcentaje_partidas_presupuestadas", "porcentaje_indicadores_seguimiento", "porcentaje_fverificacion_seguimiento", "porcentaje_gastos_seguimiento", "porcentaje_movimientos_seguimiento"
          then cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">" + caja_porcentaje(:total => 1, :valor => objeto, :sin_rotulo => true, :estilo =>  objeto_inicial.send(campo +"_estilo") ) + "</div>"
        when /advertencia/
          then cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">" +  (objeto.nil? or objeto == "" ? "&nbsp;" : icono( "alerta" )) + "</div>"
        when "grupo_tipo_periodo"
          then
            # Añadimos esta transformación para los temas de traducción del campo a otros idiomas
            objeto = case objeto
                     when "seguimiento" then _("Seguimiento")
                     when "formulacion" then _("Formulación")
                     when "prorroga" then _("Prórroga")
                     when "final" then _("Justificación Final")
                     else _(objeto)
                     end
            cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">" + objeto + "</div>"
        else
          html_class = "value_" + objeto.class.name.underscore
          # Cuando es booleano, ponemos si/no
          objeto = _("Sí") if objeto.class.name == "TrueClass"
          objeto = _("No") if objeto.class.name == "FalseClass"
          # Si es una fecha, lo pasamos al locale que le toque
          objeto = I18n.l(objeto) if objeto.class.name == "Date" || objeto.class.name == "DateTime"
          # Cuando es big_decimal, ponemos el valor formateado (con separadores de miles)
          objeto = float_a_moneda(objeto) if objeto && objeto.class.name == "BigDecimal"
          cadena = "<div id='#{id}_valor_#{nombre}' class='elemento_listado elemento#{clase} #{html_class}' title='"+h(objeto.to_s)+"'>" +( objeto && objeto.to_s != "" ? h(objeto.to_s) : "&nbsp;")   +"</div>"
      end
      # Añadimos esta forma por que los tooltips ahbituales no funcionan al refescar via Javascript
      case campo
        when "porcentaje_tareas_configuracion", "porcentaje_periodo_formulacion", "porcentaje_periodo_seguimiento_oficial", "porcentaje_periodo_seguimiento_interno", "implantacion_configuracion", "implantacion_periodos", "implantacion_formulacion", "implantacion_seguimiento", "porcentaje_objetivos_resultados_con_indicadores",  "porcentaje_objetivos_resultados_con_fverificacion",  "porcentaje_resultados_con_actividades", "porcentaje_partidas_presupuestadas", "porcentaje_indicadores_seguimiento", "porcentaje_fverificacion_seguimiento", "porcentaje_gastos_seguimiento", "porcentaje_movimientos_seguimiento"
          logger.info "x x x x x x x x x x x " + id + "_valor_" + nombre
          cadena += '<script type="text/javascript">	new Opentip("#'+ id +'_valor_'+ nombre +'", "'+ objeto_inicial.send(campo +"_rotulo") +'", { extends: "dark" }); </script> '
        when /advertencia/
          cadena += '<script type="text/javascript">	new Opentip("#'+ id +'_valor_'+ nombre +'", "'+ objeto_inicial.send(campo) +'", { extends: "alert" }); </script> ' unless objeto.nil? or objeto == ""
      end
      
    rescue
      cadena = "<div id=\""+ id +"_valor_"+ nombre +"\" class=\"elemento"+ clase +"\">&nbsp;</div>"
    end
    return cadena.html_safe
  end
  

  # paginación, se integra en final_listado
  def paginacion elementopaginado, elementosxpagina, otros={} 
    params_paginate = request.parameters 
    params_paginate.merge!(otros[:url]) if otros[:url]
    paginate_options = { params: params_paginate, previous_label: "<< ", next_label: " >>", :class => "elemento3_2_ti" }
    formulario = "<div class='fila' id='paginacion'>".html_safe + (will_paginate(elementopaginado, paginate_options) || " ")
    formulario << ("<div class='elemento1'>" + _("Por página") + ": ").html_safe 
    [20, 50, 100, 200].each do |n|
      if elementosxpagina == n
        formulario << content_tag(:b, n.to_s)
      else 
        opcion = (otros[:url] || params).merge({por_pagina: n, page: 1})
        formulario << link_to(n.to_s, url_for(opcion.merge(only_path: false)))
      end
      formulario << (n == 200 ? "" : " , ")
    end
    formulario << "</div><div class='elementoderecha'> ".html_safe + informacion_paginacion(elementopaginado)  + "</div>".html_safe
    formulario << "<div class='linea'></div></div>".html_safe
  end


  # paginacion para sublistados
  def paginacion_sublistado elementopaginado, elementosxpagina=session[:por_pagina], otros={}
    params_paginate = request.parameters 
    params_paginate.merge!(otros[:url]) if otros[:url].class.name == "Hash"
    paginate_options = { params: params_paginate, previous_label: "<< ", next_label: " >>", :class => "elemento1_ti" }
    formulario = "<div class='fila' id='paginacion'>".html_safe + (ajax_will_paginate(elementopaginado, paginate_options) || " ")
    formulario << ("<div class='elemento1'>" + _("Por página") + ": ").html_safe
    [20, 50, 100, 200].each do |n|
      if elementosxpagina == n
        formulario << content_tag(:b, n.to_s)
      else
        opcion = params_paginate.merge({por_pagina: n, page: 1})
        formulario << link_to_remote(n.to_s, url: url_for(params_paginate.merge({:por_pagina => n})),
                                             loading: "Element.show('espera')",
                                             complete: "Element.hide('espera')" )
      end
      formulario << (n == 200 ? "" : " , ")
    end
    formulario << "</div><div class='elementoderecha'> ".html_safe + informacion_paginacion(elementopaginado)  + "</div>".html_safe
    formulario << "<div class='linea'></div></div>".html_safe
  end

  # completa paginacion
  def informacion_paginacion collection
    total_entries = collection.total_entries
    if collection.total_pages < 2
      case total_entries 
      when 0; ("<b>" + _("No tiene elementos") + "</b>").html_safe
      when 1; ("<b>" + _("Mostrando 1 elemento") + "</b>").html_safe
      else;   ("<b>" + _("Mostrando todos los elementos: ") + total_entries.to_s + "</b>").html_safe
      end
    else
      (_("Mostrando elementos") + " <b>"+ (collection.offset + 1).to_s + " - " + (collection.offset + collection.length).to_s + "</b> (" + total_entries.to_s +
            " " +  _("en total") + ")").html_safe
    end
  end

  # popup con trigger click para informacion adicional de un objeto
  #   metemos este metodo para no pisar ventana_popup y permitir el cambio progresivo
  def ventana_info_popup objeto, otros={}
      objeto_id = otros[:id] ? otros[:id] : 'objeto_' + objeto.class.name + "_" + objeto.id.to_s
      cadena = '<span id="' + objeto_id + '" class="popup_link">' + icono((otros[:icono] || "informacion"), _((otros[:icono_mensaje] || "información adicional"))) + '</span>' unless otros[:fila]
      cadena = '<span id="' + objeto_id + '" class="popup_link fila_listado">' + h(otros[:fila]) + '</span>' if otros[:fila]
      cadena << '<div id="' + objeto_id + '_popup" class="popup" style="display:none">'
      for elemento in otros[:campos]
        campo = elemento[2]
        if campo.class.to_s != "Array"
          cadena << '<div class="fila"><b>' + (elemento[0]=='&nbsp;' ? campo.humanize.capitalize : elemento[0]) + ': </b>'

          valor = objeto
          campo.split('.').each { |metodo| valor = (metodo =~ /(\S+)\s(\S+)/ ? valor.send($1,$2) : valor.send(metodo)) if valor }
          if valor.class.to_s == "Array"
            valor.each do |a|
              # Ojo con este a, le he eliminado el h(a) para permitir enlaces al proyecto del gasto
              cadena << "<br>" + a unless a.class.to_s == "Array"
              # Esta linea es un poco confusa y no se si sirve para algo
              a.each { |elemento| cadena << "<br>" + h(elemento) } if a.class.to_s == "Array"
            end
          elsif campo == "porcentaje" || campo == "porcentaje_actual"
            cadena << (valor * 100).to_s + "%"
          elsif campo == "tipo" || campo == "partida.tipo" || campo == "tipo_mayusculas" || campo == "tipo.capitalize" || campo == "transferencia.first.tipo.capitalize" || campo == "tipo_asociado.capitalize"
            cadena << _(valor) if valor
          else
            valor = _("Sí") if valor.class.name == "TrueClass"
            valor = _("No") if valor.class.name == "FalseClass"
            # Si es una fecha, lo pasamos al locale que le toque
            valor = I18n.l(valor) if valor.class.name == "Date" || valor.class.name == "DateTime"
            cadena <<  h(valor.to_s)
          end
          cadena << "</div>"
        else
          objeto.send(campo[0]).each do |elemento|
            cadena << '<div class="fila"><b>' + campo[0].humanize.capitalize + '</b></div>'
            for subcampo in campo[1]
              cadena << '<div class="fila">&nbsp;&nbsp;&nbsp;&nbsp;<b>' + subcampo.humanize.capitalize + ': </b>'
              valor = elemento
              subcampo.split('.').each { |metodo| valor = (metodo =~ /(\S+)\s(\S+)/ ? valor.send($1,$2) : valor.send(metodo)) if valor }
              cadena << h(valor.to_s) + '</div>'.html_safe
            end
          end
        end
      end
      cadena << eval( 'javascript_tag "new Popup(\"' + objeto_id + '_popup\",\"' + objeto_id + '\", {trigger:\'click\'} )"' )
      cadena << '</div>'
      return cadena.html_safe
  end

  # popup con trigger click
  def ventana_popup objeto, otros={}
    #begin
      objeto_id = otros[:id] ? otros[:id] : 'objeto_' + objeto.class.name + "_" + objeto.id.to_s
      cadena = '<span id="' + objeto_id + '" class="popup_link">' + icono((otros[:icono] || "informacion"), _((otros[:icono_mensaje] || "información adicional"))) + '</span>'
      cadena << '<div id="' + objeto_id + '_popup" class="popup" style="display:none">'
      for campo in otros[:campos]
        if campo.class.to_s != "Array"
          case campo
          when /^libro/
            then cadena << '<div class="fila"><b>' + _("Cuenta") + ': </b>'
            else cadena << '<div class="fila"><b>' + _(h(campo.humanize.capitalize))  + ': </b>'
          end

          case campo
          when /^actividades|^financiadores/
            then
              objeto_nombre = objeto.class.name.downcase
              array = eval( "objeto." + objeto_nombre + "_x_actividad" ) if campo == "actividades"
              array = eval( "objeto." + objeto_nombre + "_x_agente" ) if campo == "financiadores"
              nombre = ""
              array.each{ |a|
                cadena << "<br>"
                array.each{ |x| nombre = Actividad.find( x.actividad_id).codigo} if campo == "actividades"
                array.each{ |x| nombre = Agente.find( x.agente_id).nombre} if campo == "financiadores"
                cadena << h(nombre) + " : " + (a.importe).to_s 
              }
              cadena << '</div>'

          else
              valor = objeto
              campo.split('.').each { |metodo| valor = valor.send(metodo) if valor}
              cadena << h(valor.to_s) 
              cadena << '</div>'
          end
          
          
        else
          objeto.send(campo[0]).each do |elemento|
            cadena << '<div class="fila"><b>' + campo[0].humanize.capitalize + '</b></div>'
            for subcampo in campo[1]
              cadena << '<div class="fila">&nbsp;&nbsp;&nbsp;&nbsp;<b>' + _(subcampo.humanize.capitalize) + ': </b>'
              valor = elemento 
              subcampo.split('.').each { |metodo| valor = valor.send(metodo) if valor}
              cadena << h(valor.to_s)
              cadena << '</div>'
            end
          end
        end
      end
      cadena << eval( 'javascript_tag "new Popup(\"' + objeto_id + '_popup\",\"' + objeto_id + '\", {trigger:\'click\'} )"' )
      cadena << '</div>'
      return cadena.html_safe
    #rescue
    #   '<p><span id="objeto_link_' + objeto.id.to_s + '"></span></p>'
    #end
  end

  #--
  # MENSAJES
  #++

  def mensaje texto
    return ("<div id = 'mensaje'>" + texto + "</div>").html_safe 
  end

  def mensaje_ok texto
    return ("<div id = 'mensajeok'>" + texto + "</div>").html_safe
  end

  def mensaje_error objeto, otros={}
    cadena = nil
    if objeto.class == String
      cadena = ("<div id = 'mensajeerror'>" + objeto + "</div>").html_safe
    elsif objeto.class == Array
      cadena = "<ul>" + objeto.inject("") {|suma, e | suma + "<li>" + e + "</li>"} + "</ul>"
    elsif objeto.methods.include?(:errors)
      if objeto.errors.empty?
        cadena = mensaje_ok(_("Los datos se han guardado correctamente.")) unless otros[:eliminar]
        cadena = mensaje_ok(_("Se ha eliminado correctamente.")) if otros[:eliminar]
      else
        cadena = "<div id = 'mensajeerror'>".html_safe
        cadena << (_("Se han producido errores.") + "<br>").html_safe
        objeto.errors.each {|a, m| cadena << (m + "<br>").html_safe }
        cadena += "</div>".html_safe
      end
    end
    return cadena
  end


  #--
  # TABLAS 
  #++

  # dibuja las filas de la tabla
  def fila_tabla_rotulo columnas, file_width=nil
    if file_width.blank?
      fila = '<div class = "filagris">'
    else
      fila = '<div class = "filagris rotulo-tabla" style="width:' + file_width.to_s + 'em;" >'
    end
    columnas.each_with_index do |columna, i|
      estilo  = 'elemento' + columna[1] + ' ' + ' col_tbl_rot_' + i.to_s
      estilo += ' texto_rojo' if columna[0].is_a?(Numeric) && columna[0] < 0.0
      fila << '<div class="'+ estilo + '">'
      fila << celda_formateada(columna[0])
      fila << '</div>'
      fila << '<div class="elemento1_20">&nbsp</div>'
    end
    fila << '<div class = "linea"></div></div>'
  end

  # Dibuja una tabla
  def dibuja_tabla filas, scroll=false, max_width=true
    estilo_tabla = ""
    estilo_contenedor = ""
    estilo_tabla += "width:100%;" unless max_width
    if scroll
      anchura = filas[0][:cabecera].inject(0){|sum,c| sum + 0.75 * caracteres(c[1])} if filas[0] && filas[0][:cabecera]
      estilo_contenedor = (anchura != 0 ? 'width:' + anchura.to_s + 'em;' : '') + 'max-height:500px;margin-top: 40px; overflow-y: scroll;'
      estilo_tabla += "position:relative;" if scroll
    end
    salida =  '<div class="tabla" style="' + estilo_tabla + '">'
    salida << '<div class="contenedor-tabla" style="' + estilo_contenedor + '">'
    salida << dibuja_filas_tabla(filas, scroll, anchura)
    salida << '</div></div>'
    return salida.html_safe
  end

  # Dibuja las filas de una tabla
  def dibuja_filas_tabla filas, scroll=false, anchura=1000
    salida = ""
    cabecera = Array.new
    for fila in filas
      if fila[:estilo]
        cabecera = fila[:estilo]
      end
      if fila[:cabecera]
        salida << fila_tabla_rotulo(fila[:cabecera], scroll ? anchura : nil)
        cabecera = fila[:cabecera]
        # Ponemos el scroll a false para que no me ponga cabecera fija de nuevo
        scroll = false
      end
      if fila[:contenido]
        estilo_fila = fila[:estilo_fila]||"fila"
        salida_fila = '<div class="' + estilo_fila + '">'
        fila[:contenido].each_with_index do |elemento, i|
          #logger.info "X-------->" + cabecera[i].to_s + "--" + cabecera.length.to_s + "--" + elemento.to_s
          estilo  = 'elemento' + (cabecera.length > i ? cabecera[i][1] : '1_2') + ' col_tbl_' + i.to_s
          estilo += ' texto_rojo' if elemento.is_a?(Numeric) && elemento < 0.0
          salida_fila << '<div class="' + estilo + '">' + celda_formateada(elemento,(cabecera.length > i ? cabecera[i][1] : '1_2')) + '</div>'
          salida_fila << '<div class="elemento1_20">&nbsp</div>'
        end
        if fila[:objeto_id] && fila[:objeto_tipo]
          salida_fila << '<div class="elementoderecha">'
          salida_fila << ventana_info_popup( eval(fila[:objeto_tipo].capitalize).find_by_id(fila[:objeto_id]), {:campos => campos_listado(fila[:objeto_campos]) + campos_info(fila[:objeto_campos]), :id => fila[:objeto_tipo] + fila[:objeto_id].to_s + "_informacion" + (fila[:html_id] ? "_" + fila[:html_id].to_s : "") } )
          salida_fila << '</div>'
        end
        if fila[:objeto_desplegado]
          salida_fila << '<div class="elementoderecha">'
          salida_fila << remote(icono("lista", _("Detalle")),  :url => fila[:objeto_desplegado][:url])
          salida_fila << '</div>'
          salida_fila << '<div id="borrame_' + fila[:objeto_desplegado][:url][:update] + '" class="linea"></div>'
          salida_fila << '<div class="linea" id="' + fila[:objeto_desplegado][:url][:update] + '"></div>'
        end
        # La opcion :mas_info permite pinchar en cualquier lugar de la fila y que se despliegue en un div inferior un ajax
        if fila[:mas_info] && fila[:mas_info][:url]
          salida << remote( salida_fila.html_safe, url: fila[:mas_info][:url], html: fila[:mas_info][:html])
          clase = "linea" + (fila[:mas_info][:html_mas_info] && fila[:mas_info][:html_mas_info][:class] ? " " + fila[:mas_info][:html_mas_info][:class] : "")
          salida << '<div class="' + clase + '" id="' + fila[:mas_info][:url][:update] + '"></div>'
        else
          salida << salida_fila
        end
        salida << '<div class="linea"></div></div>'
        # Incluimos un div adicional si hay mas info para sumar al listado en lugar de incluirlo como hijo
        if fila[:mas_info] && fila[:mas_info][:url]
          salida << '<div id="' + fila[:mas_info][:url][:update] + '_post"></div>'
        end
      end
    end
    return salida
  end

  # devuelve una cadena adecuada al tipo de contenido
  def celda_formateada celda, formato=nil
    # Las cadenas las devolvemos incluyendoles saltos de página forzados
    return (celda == "" ? "&nbsp;" : h(celda).gsub(/\n/,"<br>").html_safe) if celda.is_a? String
    # Las fechas las devolvemos segun los locales que estemos usando
    return I18n.l celda if celda.is_a? Date
    # Si no es ni cadena ni fecha será un número...
    # Para volcados con 'td_g', lo tratamos con 5 decimales
    if formato && formato.end_with?("_td_g")
      return float_a_moneda(celda,'%.5f')
    # Si no estamos indicando formato, o este no es td_g
    else
      # Los enteros tal cual
      return celda.to_s if celda.is_a? Integer 
      # Y el resto con dos decimales
      return float_a_moneda(celda) unless celda.is_a? Integer 
    end
  end

  # 
#  def valor_celda columna, identificador
#    valor = columna.detect {|v| v[:id] == identificador}
#    return (valor ? ('%.2f' % valor[:importe].to_s) : "&nbsp;")
#  end


  # Ventana modal (*otros para futuro uso)
  def modal( rotulo, url, titulo, otros={} )
    if eval( "@" + singularizar_seccion ) and eval( "@" + singularizar_seccion ).id and titulo != "Cambiar datos personales"
      pretitulo = _("Proyecto") if params[:seccion] == "proyectos"
      pretitulo = _("Agente") if params[:seccion] == "agentes"
      pretitulo = params[:seccion].gsub(/(.*)(s)/) {$1.gsub(/one/, "ón").capitalize} unless params[:seccion] == "proyectos" || params[:seccion] == "agentes"
      cadena = pretitulo + ": " + eval( "@" + singularizar_seccion ).nombre + "<br>".html_safe
    else
      cadena = ""
    end
    if otros[:inline]
      link_to_remote h(rotulo), :url => url, :id => (otros[:id] || ""), :class => (otros[:class]||"") 
      #link_to h(rotulo), url + {:remote => true}, (otros[:id] || "")
    else
      #link_to h(rotulo), url, :title => titulo, :onclick => "Modalbox.show(this.href, {title: '" + cadena + titulo + "', width:" + (otros[:width] ? otros[:width].to_s : "820") + (otros[:height] ? ",height:" + otros[:height].to_s : "") + "}); return false;", :id => (otros[:id] || "")
      # Si esto falla:
      #  1) Averiguar quien lo invoca
      #  2) Podria resolverse con un main_app.url_for(url) ???
      link_to h(rotulo), nil, :title => titulo, :onclick => "Modalbox.show('" + url_for(url) + "', {title: '" + cadena + titulo + "', width:" + (otros[:width] ? otros[:width].to_s : "820") + (otros[:height] ? ",height:" + otros[:height].to_s : "") + "}); return false;", :id => (otros[:id] || ""), :class => (otros[:class] || "")
    end
  end

  # Ventana modal que pide confirmacion para el borrado de un elemento
  def modal_borrado ( rotulo, url, titulo, texto, otros={} )
    # Falta añadir al titulo de la ventana modal el mismo texto superior que llevan las modales sobre la variable de session.
    cadena = '<div style="display:none;" id="'+ (otros[:id] || url[:id].to_s ) +'_modalconfirmar" class="elemento2_tc">'
    cadena << h(titulo) + ': <br><b>'.html_safe + h(texto) + '</b><br><br>'.html_safe
    cadena << '<div class="fila"><a href="#" onclick="Modalbox.hide()"> Cancelar </a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; '
    cadena << link_to( "Confirmar", url, :id => otros[:id].to_s + "_confirmar") unless otros[:ajax]
    cadena << link_to_remote( "Confirmar", :url => url, :html =>  {:id => otros[:id].to_s + "_confirmar"}) if otros[:ajax]
    cadena << '</b></div></div>'
    cadena << "<a id=\"#{ (otros[:id] || url[:id].to_s )  }\" onclick=\"Modalbox.show($('#{ (otros[:id] || url[:id].to_s )  }_modalconfirmar'), {title: '" + h(titulo) + "', width: 600,transitions:false}); return false;\" href=\"#\" title='"+ url[:action].to_s + "'>"
    cadena << h(rotulo)
    cadena << "</a>"
    return cadena.html_safe
  end


  def spinner_formulario_no_se_usa
   #return :loading =>          "Element.show('spinner'); Element.hide('botonguardar'); ", :complete => "Element.hide('spinner'); Element.show('botonguardar');"
   return {:loading => "Element.show('spinner'); Element.hide('botonguardar');", :complete => "Element.hide('spinner');Element.show('botonguardar');"}
  end

  def singularizar_seccion
    singularizar(params[:seccion])
  end

  def singularizar nombre
    nombre.gsub(/(.*)(s)/) {$1.gsub(/one/, "on")}
  end

  # Dibuja una barra de porcentaje
  #  campos[:total]	=> Valor total
  #  campos[:valor]	=> Valor medido sobre el total
  #  campos[:titulo]	=> Título del porcentaje
  #  campos[:rotulo]	=> Texto explicativo sobre la barra de porcentaje
  def caja_porcentaje campos
    cadena = campos[:url] ? '<a href="' + campos[:url] + '" class="enlace-contextual">' : ''
    estilo = nil
    valor = (campos[:valor] && campos[:valor].to_f > 0) ? campos[:valor].to_f : 0.0
    total = (campos[:total] && campos[:total].to_f >= 0) ? campos[:total].to_f : 1.0 
    porcentaje = (100*valor/total).round if total >= valor && total != 0.0
    porcentaje = 100 - (100*total/valor).round unless total >= valor || valor == 0.0
    porcentaje = 100 if total == 0.0
    estilo = "_resaltado" unless total >= valor && total != 0
    estilo = "_" + campos[:estilo] if campos[:estilo]
    estilo_caja = "caja_porcentaje_barra"
    cadena << '<div class="caja_porcentaje_contenedor '+ (campos[:sin_rotulo] ? "" : "help") + '"'
    cadena << ' title="' + (campos[:rotulo] || (total == 0 ? _("No hay datos") : (porcentaje.to_s + "%"))) + '" ' unless campos[:sin_rotulo]
    cadena << ' >'
    if campos[:titulo]
      cadena << '<div class="caja_porcentaje_titulo">' + campos[:titulo] + '</div>'
      cadena << '<div class="caja_porcentaje_contenedor_barra">'
    end
    cadena << '<div class="' + estilo_caja + ' caja_porcentaje_base' + (estilo || "") + '"></div>'
    cadena << '<div class="' + estilo_caja + ' caja_porcentaje_valor' + (estilo || "") + '" style="width:' + porcentaje.to_s + '%"></div>'
    cadena << '<div class="' + estilo_caja + '">' + (total != 0 ? (valor>total ? _("Desviación") + ": " + (100*valor/total).round.to_s : porcentaje.to_s) + "%" : "") + '</div>'
    cadena << '</div>' if campos[:titulo]
    cadena << '</div>'
    cadena << '</a>' if campos[:url]
    return cadena.html_safe
  end

  def formulario_enviar formulario, locals
      page.insert_html :top, "cabecera","<div id='capaPrueba'></div>".html_safe
      #page.show "contenedorFormulario"
      page.insert_html :before, "fila_actividad_anadir", :partial => formulario, :locals => locals
  end

  #-- 
  # NUEVOS METODOS DE CAMBIO USABILIDAD. FORMULARIOS INLINE
  #++

  def mensaje_cambio update, mensaje
    page.insert_html :before, update, :inline => "<%= cadena_mensaje_cambio mensaje %>", :locals => {:mensaje => mensaje}
    page.delay(mensaje[:errors].empty? ? 2 : 6) do
        page.remove(mensaje[:errors].empty? ? "mensajeok" : "mensajeerror")
    end

  end

  def cadena_mensaje_cambio otros={}
    script = "Element.remove('mensajeok');"
    cadena = '<div id="mensajeok">' + _("Los datos se han guardado correctamente.") if  !otros[:eliminar] and (otros[:errors].nil? or otros[:errors].empty?)
    cadena = '<div id="mensajeok">' + _("El dato se ha borrado correctamente.") if  otros[:eliminar] and  (otros[:errors].nil? or otros[:errors].empty?)
    unless (otros[:errors].nil? or otros[:errors].empty?)
      cadena = '<div id="mensajeerror">' + _("Se han producido errores.") + "<br>"
      otros[:errors].each {|a, m| cadena += m + "<br>" } if otros[:errors].class.name != "String"
      cadena += otros[:errors] if otros[:errors].class.name == "String"
      script = "Element.remove('mensajeerror');"
    end
    cadena << '<div class="elementoderecha" id="cerrarmensaje">'
    cadena << link_to_function( icono( "cerrar", _("Cerrar mensaje")), script, {:id => "formulario_cerrar"} )
    cadena << '</div></div>'
    return cadena.html_safe
  end


  def icono_borrado texto, url
    script_cerrar = "Element.hide('borradofondo');Element.hide('borrado');"
    script_abrir = "Element.show('borradofondo');Element.show('borrado');"
    cadena = link_to_function( icono("borrar", _("Eliminar")),  script_abrir )
    cadena << "<div id='borradofondo' style='display:none'> </div> <div id='borrado' style='display:none'>"
    cadena << '<div class="linea"><div class="elementoderecha" id="cerrarsublistado">'
    cadena << link_to_function( icono( "cerrar", _("Cerrar esta ventana")), script_cerrar, {:id => "ventana_cerrar"} )
    cadena << '</div></div>' + _('Va a eliminar la actividad') + ': '
    cadena << ' <br>' + texto + '<br><br>'
    cadena << '<div class="fila"><a href="#" onclick="' + script_cerrar + '">' + _("Cancelar") + '</a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; '
    cadena << link_to_remote( _("Confirmar"), :url => url )
    cadena << '</b></div></div>'
    cadena << "</div>"
  end

  #--
  # Sobrecargamos helpers para permitir funcionamiento de modulos
  #++
  def url_for(options = {})
    plugin = options.delete(:plugin)  if options.is_a?(Hash) && options.key?(:plugin)
    plugin = options.delete("plugin") if options.is_a?(Hash) && options.key?("plugin")

    if plugin
      options[:controller]  = plugin + "/" + options[:controller]  if options.key?(:controller) && options[:controller].match(/^#{plugin}/).nil?
      options['controller'] = plugin + "/" + options['controller'] if options.key?('controller') && options['controller'].match(/^#{plugin}/).nil?
      return eval(plugin).url_for(params.symbolize_keys.merge(options))
    else
      return super(options)
    end
  end

  # Conversiones entre formatos de moneda accesibles desde todas las vistas
  def float_a_moneda numero, formato='%.2f'
    number_with_delimiter((formato % (numero||0)).to_s , :separator => ",", :delimiter => ".")
  end
end

