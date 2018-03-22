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
# Nuevos metodos utilizados en todas las "views", para cambiar a edicion inline.

module NuevaEdicionHelper


  #-- 
  # NUEVOS METODOS DE CAMBIO USABILIDAD. FORMULARIOS INLINE
  #++

  # Alternativa de prueba para el formulario
  def formulario_comienzo valores={}
    script = "Element.remove('formularioinline'); Element.remove('formulariofondo'); Element.remove('formulariocontenedor'); " 
    script += "Element.show('"+ params[:update] +"')" if params[:update]
    cadena = "<div id='formulariocontenedor'><div id='formulariofondo'></div>"
    cadena << "<div id='formularioinline' >"
    cadena << '<div class="linea"><div class="elementoderecha" id="cerrarsublistado">'
    cadena << link_to_function( icono( "cerrar", _("Cerrar formulario")), script, {:id => "formulario_cerrar"} )
    cadena << '</div></div>'
    cadena << "<div id='formulariomensaje'></div>"
    cadena << form_remote_tag( :url => valores[:url], :html => {:id => "formulariocontenido"}, :multipart => true, :before => "tinyMCE.triggerSave(true, true);", :loading => "$('guardarboton_submit').disable();Element.show('espera');", :complete => "Element.hide('espera'); $('guardarboton_submit').enable();") unless valores[:target]
    cadena << form_tag( valores, :target => valores[:target], :multipart => true, :class => "formulario" ) if valores[:target]

    cadena << hidden_field("", "update", :value => params[:update])
    cadena << hidden_field("", "update_listado", :value => params[:update_listado])
    return cadena.html_safe
  end

  # submit_tag con botón guardar
  def formulario_final boton={}
    cadena = '<div class="linea"></div>'
    #cadena << '<div class="notapie">NOTA: Los campos marcados con (*) son obligatorios</div>'
    cadena << '<div id="guardarboton" >'
    cadena << submit_tag(h(boton[:texto_alternativo] || _("Guardar")), :id => "guardarboton_submit", :class => "boton") unless boton.nil?
    # Esto lo dejamos desactivado de momento, porque no sabemos el efecto que pueda tener la superposicion de 2 capa
    #if boton[:confirmar]
    #  cadena << boton_confirmar( :enlace => (boton[:texto_alternatif] || "Guardar"), :identificador => "send_form", :texto => boton[:confirmar])
    #else
    #  cadena << submit_tag((boton[:texto_alternatif] || "Guardar"), :class => "boton", "data-disable-with" => _("Enviando..."), :onclick => 'Element.show("espera")')
    #end
    cadena << "</div></div></div>"
    cadena << "</form>"
    return cadena.html_safe
  end

  # Metodo que crea una ventana modal de confirmacion sobre un boton de formulario. (se usa en el formulario antiguo)
  # Los valores fijos que es necesario pasarle son:  :url, :texto, :identificador
  # Los valores optativos son :enlace
  def boton_confirmar valores={}
    valores[:formulario_id] ||= "formulario"
    valores[:enlace] ||= icono("alerta", _("Confirmar"))
    script_cerrar = "Element.hide('"+ valores[:identificador] +"_borradofondo');Element.hide('"+ valores[:identificador] +"_borrado');"
    script_abrir = "Element.show('"+ valores[:identificador] +"_borradofondo');Element.show('"+ valores[:identificador] +"_borrado'); return false;"
    cadena = ""
    cadena << submit_tag( valores[:enlace], :onclick => script_abrir.html_safe, :class => "boton" )
    cadena << "<div id='"+ valores[:identificador] +"_borradofondo' class='borradofondo' style='display:none'> </div>"
    cadena << "<div id='"+ valores[:identificador] +"_borrado' class='borrado'  style='display:none'>"
    cadena << '<div class="linea"><div class="elementoderecha" id="cerrarsublistado">'
    cadena << link_to_function( icono( "cerrar", _("Cerrar esta ventana")), script_cerrar.html_safe, {:id => "ventana_cerrar"} )
    cadena << '</div></div>'
    cadena << valores[:texto]
    cadena << "<br/><br/>"
    cadena << '<div class="fila"><a href="#" onclick="' + script_cerrar + '" > Cancelar </a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
    cadena << link_to_function( _("Confirmar"), "Element.show('espera');$(#{valores[:formulario_id]}).submit()" )
    cadena << '</b></div>'
    cadena << "</div>"
    return cadena.html_safe
  end

  # Metodo que crea una ventana modal de aviso.
  # Los valores fijos que es necesario pasarle son:  :texto, :identificador
  def mensaje_advertencia valores={}
    valores[:enlace] ||= icono("alerta", _("Confirmar"))
    script_cerrar = "Element.hide('"+ valores[:identificador] +"_borradofondo');Element.hide('"+ valores[:identificador] +"_borrado');"
    script_abrir = "Element.show('"+ valores[:identificador] +"_borradofondo');Element.show('"+ valores[:identificador] +"_borrado'); return false;"
    cadena = ""
    cadena << "<div id='"+ valores[:identificador] +"_borradofondo' class='borradofondo' style='display:none'> </div>"
    cadena << "<div id='"+ valores[:identificador] +"_borrado' class='borrado'  style='display:none'>"
    cadena << '<div class="linea"><div class="elementoderecha" id="cerrarsublistado">'
    cadena << link_to_function( icono( "cerrar", _("Cerrar esta ventana")), script_cerrar.html_safe, {:id => "ventana_cerrar"} )
    cadena << '</div></div>'
    if valores[:texto]
      cadena << '<div class="linea"><br>'
      cadena << valores[:texto]
      cadena << "</div><br/>"
    end
    if valores[:partial]
      cadena << render( valores[:partial], valores[:locals] )
    end
    cadena << '<div class="fila"><a href="#" onclick="' + script_cerrar + '" >' + (valores[:texto_cerrar]||_("Aceptar")) + '</a></div>'
    cadena << "</div>"
    return cadena.html_safe
  end

  def icono_vinculo url, imagen, titulo, otros={}
    link_to_remote  icono( imagen, titulo ), :url=>  url, :loading => "Element.show('espera');", :complete => "Element.hide('espera');" 
  end

  # Los valores fijos que es necesario pasarle son:  :url
  def editar valores={}
    valores[:enlace] = icono("editar", _("Editar"))
    if valores[:confirmar]
      valores[:identificador] = (valores[:identificador]||"") + "_editar"
      valores[:solo_aviso] = true
      valores[:texto] = valores[:confirmar]
      confirmar(valores).html_safe
    else
      link_to_remote valores[:enlace], url: valores[:url], html: { id: (valores[:url][:update]||"").to_s + "_editar"}, loading: "Element.show('espera');", complete: "Element.hide('espera');" 
    end
  end

  def copiar valores={}
    link_to_remote  icono( "anadir", _("Copiar")), :url=>  valores[:url], :html => { :id => (valores[:url][:update]||"").to_s + "_copiar"}, :loading => "Element.show('espera');", :complete => "Element.hide('espera');"
  end

  # Los valores fijos que es necesario pasarle son:  :url
  def anadir valores={}
    link_to_remote  icono( "anadir", _("Añadir uno nuevo")), :url=>  valores[:url], :html => { :id => (valores[:url][:update]||"").to_s + "_anadir"}, :loading => "Element.show('espera');", :complete => "Element.hide('espera');" 
  end



  def cadena_mensaje otros={}
    if otros[:informacion]
      cadena = '<div id="mensajecorrecto">' + otros[:informacion]
    else
      cadena = '<div id="mensajecorrecto">' + _("Los datos se han guardado correctamente.") if  !otros[:eliminar] and (otros[:errors].nil? or otros[:errors].empty?)
      cadena = '<div id="mensajecorrecto">' + _("El dato se ha borrado correctamente.") if  otros[:eliminar] and  (otros[:errors].nil? or otros[:errors].empty?)
    end
    unless (otros[:errors].nil? or otros[:errors].empty?)
      cadena = '<div id="mensajefallo" style="margin-top:-' + (40 + 15*otros[:errors].size).to_s + ' ;" >' + _("Se han producido errores.") + "<br>"
      otros[:errors].each {|a, m| cadena += m + "<br>" }
    end
    cadena << '<div class="linea" ></div>'
    cadena << "</div>"
  end

  # Metodo que crea una ventana modal de confirmacion.
  # Los valores fijos que es necesario pasarle son:  :url, :texto, :identificador
  # Los valores optativos son :enlace
  def confirmar valores={}
    valores[:enlace] ||= icono("alerta", _("Confirmar"))
    script_cerrar = "Element.hide('"+ valores[:identificador] +"_borradofondo');Element.hide('"+ valores[:identificador] +"_borrado');Element.hide('"+ valores[:identificador] +"_confirmacion');Element.hide('"+ valores[:identificador] +"_boton_confirma_segunda');"
    script_abrir = "Element.show('"+ valores[:identificador] +"_borradofondo');Element.show('"+ valores[:identificador] +"_borrado');Element.show('"+ valores[:identificador] +"_pregunta');Element.show('"+ valores[:identificador] +"_boton_confirma');"
    cadena = ""
    cadena << link_to_function( valores[:enlace],  script_abrir.html_safe, :id => (valores[:url] && valores[:url][:update] && valores[:url][:action] ? valores[:url][:update] + "_" + valores[:url][:action] : "confirmar") )
    cadena << "<div id='"+ valores[:identificador] +"_borradofondo' class='borradofondo' style='display:none'> </div>"
    cadena << "<div id='"+ valores[:identificador] +"_borrado' class='borrado'  style='display:none'>"
    cadena << '<div class="linea"><div class="elementoderecha" id="cerrarsublistado">'
    cadena << link_to_function( icono( "cerrar", _("Cerrar esta ventana")), script_cerrar.html_safe, {:id => "ventana_cerrar"} )
    cadena << '</div></div>'
    cadena << "<div id='"+ valores[:identificador] +"_pregunta'>"
    cadena << h(valores[:texto]) 
    cadena << "</div>"
    cadena << "<div id='"+ valores[:identificador] + "_confirmacion' style='display:none'></div>"
    cadena << "<br/><br/>"
    cadena << '<div class="fila"><a href="#" onclick="' + script_cerrar + '" > ' + _('Cancelar') + ' </a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
    if valores[:solo_aviso]
      cadena << link_to_remote( _("Confirmar"), url: valores[:url], html: {id: valores[:identificador] + "_boton_confirma"},
                                loading: "Element.show('espera');",
                                complete: "Element.hide('espera');Element.hide('"+ valores[:identificador] +"_borradofondo');Element.hide('"+ valores[:identificador] +"_borrado');" )
    else
      cadena << link_to_remote( _("Confirmar"), :url => valores[:url], :html => {id: valores[:identificador] + "_boton_confirma"}, :loading => "Element.show('espera');", :complete => "Element.hide('espera');" )
      cadena << link_to_remote( _("Sí, Confirmar"), :url => valores[:url].merge(doble_confirmacion: true), :html => {style: "display:none", id: valores[:identificador] + "_boton_confirma_segunda"}, :loading => "Element.show('espera');", :complete => "Element.hide('espera');" )
    end
    cadena << '</b></div>'
    cadena << "</div>"
    return cadena.html_safe
  end

  # Metodo que crea una ventana modal de borrado.
  # Los valores fijos que es necesario pasarle son:  :url, :texto, :identificador
  def borrado valores={}
    valores[:enlace] = icono("borrar", _("Eliminar"))
    valores[:texto] = (_("Va a eliminar") + ": <br/>").html_safe + h(valores[:texto])
    return confirmar(valores).html_safe
  end

  # Metodo (VIEJO) que crea una ventana modal de borrado.
  # Los valores fijos que es necesario pasarle son:  :url, :texto, :identificador
  def borrado_viejo  valores={}
    script_cerrar = "Element.hide('"+ valores[:identificador] +"_borradofondo');Element.hide('"+ valores[:identificador] +"_borrado');"
    script_abrir = "Element.show('"+ valores[:identificador] +"_borradofondo');Element.show('"+ valores[:identificador] +"_borrado');"
    cadena = link_to_function( icono("borrar", "Eliminar"),  script_abrir )
    cadena << "<div id='"+ valores[:identificador] +"_borradofondo' class='borradofondo' style='display:none'> </div>"
    cadena << "<div id='"+ valores[:identificador] +"_borrado' class='borrado'  style='display:none'>"
    cadena << '<div class="linea"><div class="elementoderecha" id="cerrarsublistado">'
    cadena << link_to_function( icono( "cerrar", _("Cerrar esta ventana")), script_cerrar, {:id => "ventana_cerrar"} )
    cadena << '</div></div>'
    cadena << _("Va a eliminar") + ":"
    cadena << ' <br>' + h(valores[:texto]) + '<br><br>'
    cadena << '<div class="fila"><a href="#" onclick="' + script_cerrar + '" > ' + _("Cancelar") + ' </a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
    cadena << link_to_remote( _("Confirmar"), :url => valores[:url], :html => {}, :loading => "Element.show('espera');", :complete => "Element.hide('espera');" )
    cadena << '</b></div>'
    cadena << "</div>"
    return cadena.html_safe
  end

  def listado cabecera, otros={}
   cadena = ""
   cadena << comienzo_listado(otros[:identado])
   cadena << "<div class='filacabecera' id='filacabecera'>"
   cadena << cabecera.inject(""){|todos, e| todos + h(elemento_cabecera(e[0], e[1], e[2], e[3])) }
   cadena << "<div class='elementoderecha'>"
   #cadena << link_to( icono( "seleccionar", h(@resumen[:mensaje] || _("Ver resumen" )) ), @resumen[:url], :popup => ['Resumen','width=1024, height=750, toolbar=no, location=yes,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes']  ) if @resumen
   cadena << link_to( icono( "seleccionar", h(@resumen[:mensaje] || _("Ver resumen" )) ), @resumen[:url], :target => '_blank'  ) if @resumen
   cadena << link_to( icono( "descargar", _("Exportar a XLS" )), request.parameters.merge({:format => :xls, :format_xls_count => (@formato_xls.to_i+1)}) )  if @formato_xls
   cadena << remote( icono("informacion", _("Información del listado")), :url => url_for(@listado_mas_info), :html => {:id => "mas_info_listado"}) if @listado_mas_info
   cadena << link_to( icono( "descargar", otros[:descargar][:texto_enlace]||_("Descargar")), otros[:descargar][:url] ) if otros[:descargar]
   cadena << borrado(:url => otros[:listado_borrar_todo], :texto => "Todos los elementos del listado", :identificador => "filacabecera") if otros[:listado_borrar_todo]
   cadena << anadir(:url => otros[:url]) unless otros[:anadir] == false
   cadena << link_to_function( icono( "cerrar", _("Cerrar este listado")),  "document.getElementById('" + otros[:id_listado] + "').innerHTML=\"\";", {:id => "cerrar_listado"} ) if otros[:cerrar_listado] && otros[:id_listado]
   cadena << "</div><div class='linea'></div></div>"
   return cadena.html_safe
  end

  # Personalizacion de link_to_remote, con la principal funcion de poner "loading" y "complete"
  def remote rotulo, valores={}
    if valores[:url]
      link_to_remote rotulo, :url => valores[:url], :html => valores[:html], :loading => "Element.show('espera')", :complete => "Element.hide('espera')"
    elsif valores[:function]
      link_to_function rotulo, valores[:function], valores[:html]
    end
  end

  # Personalizacion de link_to_remote, con la principal funcion de usar un icono y poner "loading" y "complete"
  def icono_remote tipo, rotulo, valores={}
    link_to_remote icono(tipo, rotulo, (valores[:html] && valores[:html][:id] ? valores[:html][:id] + "_icono" : nil)), :url => valores[:url], :html => valores[:html], :loading => "Element.show('espera')", :complete => "Element.hide('espera')"
  end

  #--
  # RUTINAS AJAX
  #++


  # Los valores fijos que es necesario pasarle es :partial, :update, y puede llevar adicionalmente :locals y :mensaje_formulario
  def formulario valores={}
    mensaje_informacion valores[:update], valores[:mensaje_formulario] if valores[:mensaje_formulario]
    page.insert_html :after, valores[:update], :partial => valores[:partial] , :locals => valores[:locals]
    page.visual_effect :highlight, valores[:update], :duration => 4 
    page.call :activaSelectoresChosen
  end


  # Los valores fijos que es necesario pasarle son: :update, :mensaje, :partial
  def modificar valores={}
    page.remove "formularioinline"
    page.remove "formulariofondo"
    page.remove "formulariocontenedor"
    page.actualizar valores
  end

  # Los valores fijos que es necesario pasarle son: :update ó :update_listado, :mensaje, :partial, y opcionalmente puede incluir :locals
  # El comportamiento es diferente si pasamos :update (replace) o :update_listado (replace_html) 
  def actualizar valores={}
    update = valores[:update] ? valores[:update] : valores[:update_listado]
    page.mensaje_actualizacion(update, valores[:mensaje]) if valores[:mensaje]
    #locals =  valores[:locals] ? valores[:locals] : ( valores[:update] ? {:update => valores[:update] } : { :update_listado => valores[:update_listado] })
    locals = valores[:locals] || Hash.new
    locals[:update] ||= valores[:update] if valores[:update]
    locals[:update_listado] ||= valores[:update_listado] if valores[:update_listado]
    page.replace update, :partial => valores[:partial], :locals => locals if valores[:update]
    page.replace_html update, :partial => valores[:partial], :locals => locals if valores[:update_listado]
    page.visual_effect :highlight, (valores[:highlight] || update), :duration => 5 
  end

  def nueva_fila valores={}
    page.remove "formularioinline", "formulariofondo", "formulariocontenedor"
    valores[:locals][:update] = valores[:nueva_fila] if valores[:locals]
    page.insert_html :after, valores[:update], :partial => valores[:partial] , :locals => valores[:locals]
    page.visual_effect :highlight, valores[:nueva_fila], :duration => 5
    page.mensaje_actualizacion valores[:nueva_fila], valores[:mensaje]
  end

  # Los valores fijos que es necesario pasarle son: :update, :mensaje, :partial
  def eliminar valores={}
    page.visual_effect :highlight, valores[:update], :duration => 5 if valores[:partial].nil?
    page.mensaje_actualizacion valores[:update], valores[:mensaje] if valores[:partial].nil?
    page.visual_effect(:fade, valores[:update]) if valores[:mensaje][:errors].empty? && valores[:partial].nil?
    page.actualizar valores if valores[:partial]
  end 

 
  def mensaje_actualizacion update, mensaje
    page.insert_html :before, update, :inline => "<%= cadena_mensaje(mensaje).html_safe %>", :locals => {:mensaje => mensaje}
    page.delay(mensaje[:errors].empty? ? 3 : 6) do
      page.remove(mensaje[:errors].empty? ? "mensajecorrecto" : "mensajefallo")
    end
  end

  def mensaje_informacion update, mensaje, valores={}
    tipo_mensaje = valores[:tipo_mensaje] ? valores[:tipo_mensaje] : 'mensajeinfo'
    page.insert_html :before, update, :inline => "<div id='" + tipo_mensaje + "'><%= mensaje %></div>", :locals => {:mensaje => mensaje}
    page.delay(6) { page.remove(tipo_mensaje)}
  end

# Los valores fijos que es necesario pasarle son: :mensaje, :partial
  def recargar_formulario valores={}
    page.remove "formulariofondo"
    page.replace "formularioinline", :partial => valores[:partial], :locals => valores[:locals]
    page.mensaje_actualizacion "formularioinline", valores[:mensaje]
  end


 # Sustituye al helper de auto_complete para presentar los resultados
 def auto_complete_result_3(entries, field, phrase = nil)
    return unless entries
    items = entries.map { |entry| phrase ? highlight(entry[field], phrase) : h(entry[field]) }
    result = "<ul>"
    items.uniq.each { |li|
      result << "<li>" + li + "</li>"
    }
    result << "<ul>" 
    return result.html_safe
  end

end
