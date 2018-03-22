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
# metodos utilizados en las "views" del Cronograma

module CronogramaHelper

  # Dibuja la cabecera del cronograma.
  #   objeto => hash con :etiqueta, :fecha_inicio, :fecha_fin
  def cronograma_inicio objeto={}
   cadena = '<div class="listado">'
   cadena << '<div style="min-height:200;width:1020;overflow:auto;">'
   cadena << "<div class='filacabecera crono' style='vertical-align:middle;width:" + (200 + 27*(objeto[:duracion]+1)).to_s + "'>\n" unless objeto[:sin_truncar]
   cadena << "<div class='filacabecera crono' style='vertical-align:middle;width:" + (300 + 27*(objeto[:duracion]+1)).to_s + "'>\n" if objeto[:sin_truncar]
   cadena << '<div id="crono_etiqueta" class="elemento1">' + objeto[:etiqueta] + '</div>' unless objeto[:sin_truncar]
   cadena << '<div id="crono_etiqueta" class="elemento3_2">' + objeto[:etiqueta] + '</div>' if objeto[:sin_truncar]

   fecha_inicio = objeto[:fecha_inicio]
   for mes in (1..objeto[:duracion])
     fecha_crono = I18n.l(fecha_inicio + (mes-1).month, :format => "%B %Y")
     cadena << '<div id="crono_mes_' + mes.to_s + '" class="elemento1_8 elemento_centrado elemento_tabla" title="' + fecha_crono + '">' + mes.to_s + '</div>'
   end

   cadena << "<div class='linea'></div></div>\n"
   return cadena.html_safe
  end

  # Dibuja una línea de actividad del cronograma.
  def cronograma_actividad etapa, actividad, sin_truncar=false
    # Dibuja una linea de cronograma de actividad
    update = 'crono_' + actividad.id.to_s 
    cadena =  '<div id="' + update + '" class="linea crono" style="width:' + (202 + 27*(etapa.periodos+1)).to_s + '">' unless sin_truncar
    cadena =  '<div id="' + update + '" class="linea crono" style="width:' + (302 + 27*(etapa.periodos+1)).to_s + '">' if sin_truncar
    titulo = '<strong>' + h(actividad.codigo_descripcion) + '</strong>'
    axe = actividad.actividad_x_etapa.find_by_etapa_id(etapa.id)
    titulo += '<br/><br/>' + _('Estado') + ':&nbsp;<strong>' + (axe && axe.estado_actual && axe.estado_actual.realizada ? _("Cerrada") + " (" + I18n.l(axe.estado_actual.fecha) + ")" : _("Abierta")) + '</strong><br/>' if @proyecto.definicion_estado && params[:menu] == "ejecucion_tecnica"
    #url = {:update_listado => update, :action => 'modificar_abrir_cerrar_actividad', :actividad_id => actividad.id, :etapa_id => etapa.id, :update => update }
    subcadena = '<div id="' + update + '_etiqueta" class="elemento1 elemento_tabla elemento_listado help' + (params[:menu] == "ejecucion_tecnica" && (axe.nil? || axe.estado_actual.nil? || !axe.estado_actual.realizada) ? ' rojo' : '') + '" title="' + h(titulo) + '">' unless sin_truncar
    subcadena = '<div id="' + update + '_etiqueta" style="border: dotted 1px #ccc;" class="elemento3_2 elemento_tabla2 help' + (params[:menu] == "ejecucion_tecnica" && (axe.nil? || axe.estado_actual.nil? || !axe.estado_actual.realizada) ? ' rojo' : '') + '" title="' + h(titulo) + '">' if sin_truncar
    subcadena << h(truncate( actividad.codigo_descripcion, :length => ( caracteres("3_2") || 13 ))) unless sin_truncar
    subcadena << h(actividad.codigo_descripcion) if sin_truncar
    subcadena << '</div>'
    #cadena << link_to_remote(subcadena, :url => url, :loading => "Element.show('espera');", :complete => "Element.hide('espera');") if params[:menu] == "ejecucion_tecnica"
    cadena << subcadena

    # Meses de actividades
    for mes in (1..etapa.periodos)
      formulado = ActividadDetallada.find_by_mes(mes, :conditions => { :etapa_id => etapa.id, :actividad_id => actividad.id, :seguimiento => false}) ? true : false
      ejecutado = ActividadDetallada.find_by_mes(mes, :conditions => { :etapa_id => etapa.id, :actividad_id => actividad.id, :seguimiento => true}) ? true : false
      subupdate = update + '_mes_' + mes.to_s
      
      if @proyecto.definicion_estado && params[:menu] == "ejecucion_tecnica" 
        cadena << render(:partial => "mes_cronograma", :locals => { :update => subupdate, :seguimiento => true, :formulado => formulado, :ejecutado => ejecutado, :mes => mes, :tipo => 'actividad', :objeto_id => actividad.id.to_s, :etapa_id => etapa.id.to_s, :clickable => @permitir_ejecucion })
      else
        cadena << render(:partial => "mes_cronograma", :locals => { :update => subupdate, :seguimiento => false, :formulado => formulado, :ejecutado => ejecutado, :mes => mes, :tipo => 'actividad', :objeto_id => actividad.id.to_s, :etapa_id => etapa.id.to_s, :clickable => @permitir_formulacion })
      end
    end

    cadena << '<div id="' + update + '_sub" class="linea"></div>'
    cadena << '</div>'

    return cadena.html_safe
  end

  # Dibuja una línea de actividad vinculada
  def cronograma_actividad_pac actividad
    update = 'crono_actividad_pac' + actividad.id.to_s
    cadena =  '<div id="' + update + '" class="linea crono">'
    titulo  = '<br/><strong>' + h(actividad.proyecto.nombre) + '</strong><br/>'
    titulo += '<br/><strong>' + h(actividad.codigo_descripcion) + '</strong>'
    axe = actividad.actividad_x_etapa.last
    titulo += '<br/><br/>' + _('Estado') + ':&nbsp;<strong>' + ((axe && axe.estado_actual && axe.estado_actual.realizada) ? _("Cerrada") : _("Abierta")) + '</strong><br/><br/>'  if @proyecto.definicion_estado && params[:menu] == "ejecucion_tecnica"
    cadena << '<div id="' + update + '_etiqueta" class="elemento1_c elemento_tabla help' + (params[:menu] == "ejecucion_tecnica" && axe && axe.estado_actual && !axe.estado_actual.realizada ? ' rojo' : '') + '" title="' + h(titulo) + '">'
    cadena << h(truncate( actividad.codigo_descripcion + " (" + actividad.proyecto.nombre + ")", :length => ( caracteres("3_2") || 13 )))
    cadena << '</div></div>'
    return cadena.html_safe
  end

  def cronograma_subactividad etapa, actividad, subactividad, sin_truncar=false
    update = 'crono_' + actividad.id.to_s + '_subactividad_' + subactividad.id.to_s
    cadena = '<div id="' + update + '" class="linea crono" style="width:' + (202 + 27*(etapa.periodos+1)).to_s + '">' unless sin_truncar
    cadena = '<div id="' + update + '" class="linea crono" style="width:' + (302 + 27*(etapa.periodos+1)).to_s + '">' if sin_truncar
    titulo = '<strong>' + subactividad.descripcion + '</strong>'
    titulo += '<br/><br/>' + _('Estado') + ':&nbsp<strong>' + (subactividad.estado_actual ? subactividad.estado_actual.estado.capitalize : _("Sin definir") ) + '</strong>&nbsp;/&nbsp;' + _('Porcentaje') + ':&nbsp;<strong>' + (subactividad.porcentaje_actual * 100).to_s + '&nbsp%</strong><br/>' if @proyecto.definicion_estado && params[:menu] == "ejecucion_tecnica"
    #url = {:update_listado => update, :action => 'estado_subactividad', :id => subactividad.id, :etapa_id => etapa.id, :actividad_id => actividad.id, :update => update + "_sub" }
    subcadena = '<div id="' + update + '_etiqueta" class="elemento1_c elemento_tabla help' + (params[:menu] == "ejecucion_tecnica" && subactividad.porcentaje_actual != 1 ? ' rojo' : '') + '" title="' + h(titulo) + '">' unless sin_truncar
    subcadena = '<div id="' + update + '_etiqueta" style="border: dotted 1px #ccc;" class="elemento3_2 elemento_tabla2 help' + (params[:menu] == "ejecucion_tecnica" && subactividad.porcentaje_actual != 1 ? ' rojo' : '') + '" title="' + h(titulo) + '">' if sin_truncar
    subcadena << h(truncate( subactividad.descripcion, :length => ( caracteres("3_2") || 13 ))) unless sin_truncar
    subcadena << subactividad.descripcion if sin_truncar
    subcadena <<  '</div>'
    cadena << subcadena
    # Meses de subactividades
    for mes in (1..etapa.periodos)
      subupdate = update + "_mes_" + mes.to_s
      formulado = SubactividadDetallada.find_by_mes(mes, :conditions => { :etapa_id => etapa.id, :subactividad_id => subactividad.id, :seguimiento => false}) ? true : false
      ejecutado = SubactividadDetallada.find_by_mes(mes, :conditions => { :etapa_id => etapa.id, :subactividad_id => subactividad.id, :seguimiento => true}) ? true : false
      if @proyecto.definicion_estado && params[:menu] == "ejecucion_tecnica"
        cadena << render(:partial => "mes_cronograma", :locals => { :update => subupdate, :seguimiento => true, :formulado => formulado, :ejecutado => ejecutado, :mes => mes, :tipo => 'subactividad', :objeto_id => subactividad.id.to_s, :etapa_id => etapa.id.to_s, :clickable => @permitir_ejecucion })
      else
        cadena << render(:partial => "mes_cronograma", :locals => { :update => subupdate, :seguimiento => false, :formulado => formulado, :ejecutado => ejecutado, :mes => mes, :tipo => 'subactividad', :objeto_id => subactividad.id.to_s, :etapa_id => etapa.id.to_s, :clickable => @permitir_formulacion })
      end
    end

    cadena << '<div id="' + update + '_sub" class="linea"></div>'
    cadena << '</div>'
    return cadena.html_safe
  end

  def cronograma_fin
    cadena = '<div id="spinner_centrado" style="display:none"></div></div>'
    cadena << '</fieldset>'
    return cadena.html_safe 
  end

end
