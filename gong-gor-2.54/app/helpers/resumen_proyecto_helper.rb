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

module ResumenProyectoHelper


  # Metodo que dibuja un resumen de informacion incluyendo el titulo y la tabla. Utiliza tabla_resumen.
  def resumen tabla, otros={}
    cadena = '<fieldset>'
    cadena << '<div class="legend">'
    for fila_titulo in tabla[:titulo]
      cadena <<  fila_titulo + '<br>'
    end
    cadena << '<div class = "linea"></div></br></div>'
    cadena << tabla_resumen(tabla[:datos], tabla[:columnas], tabla[:filas], tabla[:otros].merge(otros))
    cadena <<  '</fieldset>'
    return cadena.html_safe
  end

  # Metodo que dibuja una tabla. Utiliza fila_tabla_resumen.
  # * datos: matriz con los datos en forma de array de hash con forma: {"importe", "columna_id", "fila_id"}
  # * columnas y filas: array de array con forma {"id", "nombre"} 
  # En "otros" (campos adicionales) puede incluirse: :columna_suma, :id_grafica
  def tabla_resumen datos, columnas, filas, otros={}
    clases = otros[:clases] || ["","1","1_2_td","3_2","2_3_td"]
    texto_columna_suma =       otros[:columna_suma] == true ? _('Totales') : otros[:columna_suma].to_s
    texto_columna_resta =      otros[:columna_resta] == true ? _('Diferencia') : otros[:columna_resta].to_s
    texto_columna_desviacion = otros[:columna_desviacion] == true ? _('% Desviacion') : otros[:columna_desviacion].to_s
    texto_columna_pctparcial = otros[:columna_pctparcial] == true ? _('% Realizado') : otros[:columna_pctparcial].to_s
    texto_columna_porcentaje = otros[:columna_porcentaje] == true ? _('Porcentaje') : otros[:columna_porcentaje].to_s
    cadena = '<div class = "tabla">'
    # Ponemos un ancho para las filas
    #@ancho_fila = "style='vertical-align:middle;margin:0 auto;width:" + (900).to_s + ";'"
    @ancho_fila = "style='vertical-align:middle;margin:0 auto;width:" + (otros[:ancho_fila] || 900).to_s + ";'"
    # pintamos la primera fila con los nombres de las columnas
    cadena << '<div class = "fila'+clases[0]+'" '+ @ancho_fila + ' ><b><div class="elemento'+clases[1]+'">&nbsp;</div>' unless otros[:sin_truncar]
    cadena << '<div class = "fila'+clases[0]+'" '+ @ancho_fila + ' ><b><div class="elemento'+clases[3]+'">&nbsp;</div>' if otros[:sin_truncar]
    cadena << columnas.inject('') {|suma, c| suma + '<div class="elemento'+ clases[2] +'" title = "'+h(c["nombre"])+'">'+ h(truncate(c["nombre"], :length => 13)) +'</div>' } unless otros[:sin_truncar]
    cadena << columnas.inject('') {|suma, c| suma + '<div class="elemento'+ clases[4] +'" title = "'+h(c["nombre"])+'">'+ h(c["nombre"]) +'</div>' } if otros[:sin_truncar]
    # Incluimos columna de totales si los hubiese.
    cadena << '<div class="elemento'+ clases[2] +'">' + texto_columna_suma + '</div>' if otros[:columna_suma]
    cadena << '<div class="elemento'+ clases[2] +'">' + texto_columna_resta + '</div>' if otros[:columna_resta]
    cadena << '<div class="elemento'+ clases[2] +'">' + texto_columna_desviacion + '</div>' if otros[:columna_desviacion]
    cadena << '<div class="elemento'+ clases[2] +'">' + texto_columna_pctparcial + '</div>' if otros[:columna_pctparcial]
    cadena << '<div class="elemento'+ clases[2] +'">' + texto_columna_porcentaje + '</div>' if otros[:columna_porcentaje]
    # Para estos totales creamos una variable global con el total de todos los datos:
    #@suma_total = datos.inject(0) {|sum, d| sum + (d.importe || 0)} if otros[:fila_porcentaje] or otros[:columna_porcentaje]
    @suma_total = datos.inject(0) {|sum, d| sum + (d["importe"] || 0)} if otros[:fila_porcentaje] or otros[:columna_porcentaje]
    cadena << '</b><div class ="linea"></div></div>'
    # OJO!... este codigo esta mal. Aunque se le pase la clase tenemos que repetir en varios sitios los valores
    clases = [otros[:clases][0], otros[:clases][3], otros[:clases][4]] || ["","3_2","2_3_td"] if otros[:sin_truncar]
    # recorremos fila a fila
    tipo_fila = filas.first["tipo"] unless filas.empty?
    for fila in filas
      # Si se pasa la variable fila_suma_columnas_tipo intercalamos una fila de TOTALES del tipo
       if otros[:fila_suma_columnas_tipo] and fila["tipo"] != tipo_fila
          cadena << fila_suma_columnas(datos, columnas, clases, otros.merge({tipo: tipo_fila, filas: filas}))
          tipo_fila = fila["tipo"]
       end
       # Comprobamos que la fila no este vacia si se ha pasado el parametro sin_fila_vacia
       unless otros[:sin_fila_vacia] and fila_vacia(datos, fila["id"])
         (cadena << fila_tabla_resumen( datos, columnas, fila, clases, otros )) if fila
       end
       # OJO!... este codigo esta mal. Aunque se le pase la clase tenemos que repetir en varios sitios los valores
       clases = [otros[:clases][0], otros[:clases][3], otros[:clases][4]] || ["","3_2","2_3_td"] if otros[:sin_truncar]
    end    
    cadena << fila_suma_columnas(datos, columnas, clases, otros.merge({tipo: tipo_fila, filas: filas})) if otros[:fila_suma_columnas_tipo]
    cadena << fila_suma_columnas(datos, columnas, clases, otros) if otros[:fila_suma]
    cadena << fila_porcentaje_columnas(datos, columnas, clases) if otros[:fila_porcentaje]
    cadena << "<br><br></div>"
    cadena << grafica_tabla_resumen(otros[:id_grafica], datos, columnas, filas) if otros[:id_grafica]
    return cadena.html_safe
  end

  # Metodo que devuelve una grafica de barras
  def grafica_tabla_resumen contenedor_id, datos, columnas, filas
    series = '<div id="boton_grafica" class="fila"><div class = "elementoderecha">' + link_to_function(icono( "grafica", _("Ver Gráfica") ),"Element.hide('boton_grafica');Element.show('" + contenedor_id + "')") + '</div></div>'
    # Metemos el javascript para las graficas
    series << "<script>var series = ["
    # Carga las etiquetas
    col = {}
    i = 0
    for columna in columnas
      col[columna["id"]] = i
      series << "{label:'" + h(columna["nombre"]) + "',data:[]},"
      i+=1
    end
    series << "];"
    # Metemos las marcas del eje de las X
    series << "var ticks = ["
    for fila in filas
      series << "[" + (fila["id"] + 0.5).to_s + ",'" + fila["nombre"] + "'],"
    end
    series << "];"
    # Carga los datos
    max = 0
    for fila in filas
      for columna in columnas
        series << "series[" + col[columna["id"]].to_s + "]['data'].push([" + fila["id"].to_s + "," + valor_dato(datos, fila["id"], columna["id"]).to_s + "]);"
      end
      # Para calcular el punto mas a la derecha
      max = fila["id"] if fila["id"] > max
    end
    # Mete un punto mas a la derecha para ajustar margenes
    series << "series[0]['data'].push([" + (max+1).to_s + ", 0]);"
    # Termina el script
    series << "</script>"
    # Y dibuja la grafica
    series << render(:partial => "comunes/grafica_barras", :locals => {:contenedor_id => contenedor_id})
    return series.html_safe
  end

  # Metodo que dibuja una fila de una tabla. Lo utiliza tabla resumen aunque puede utilizarse directamente.
  def fila_tabla_resumen datos, columnas, valores_fila, clases, otros={}
    id_fila = "fila_" + valores_fila["id"].to_s
    fila = '<div class = "fila'+ clases[0] + ' ' + (valores_fila["clase"]||'') +'" '+ @ancho_fila + ' id="' + id_fila + '">'
    fila << '<div class="elemento'+ clases[1] +'" title="'+ valores_fila["nombre"]+'" id="' + id_fila + '_titulo">' 
    if valores_fila["url"]
      fila <<  link_to_remote( truncate(valores_fila["nombre"], :lenght => caracteres(clases[1])) , :update => valores_fila["update"], :url=>valores_fila["url"] ,:loading => "Element.show('spinner')", :complete => "Element.hide('spinner')")
    else
      fila << truncate(valores_fila["nombre"], :length => caracteres(clases[1])) unless otros[:sin_truncar]
      fila << valores_fila["nombre"] if otros[:sin_truncar]
    end
    fila << '</div>'
    for columna in columnas
      id = "celda_" + valores_fila["id"].to_s + "_" + columna["id"].to_s
      valor = valor_dato(datos, valores_fila["id"], columna["id"]) 
      rojo = (otros[:marcar_valores_negativos] and valor.is_a?(Numeric) and valor < 0) ? "texto_rojo" : ""
      # Si hay un title y hemos marcado la propiedad title lo introducimos
      if otros[:celdas_title] == true
        celda = datos.find {|d| d["fila_id"].to_s == valores_fila["id"].to_s and d["columna_id"].to_s == columna["id"].to_s }
        title = (celda and celda["title"]) ? celda["title"] :  ""
        fila << '<div class="elemento'+ clases[2] +' '+ rojo + '" id="' + id + '" title ="'+ title +'">' + celda_formateada(valor) + '</div>'
      else
        fila << '<div class="elemento'+ clases[2] +' '+ rojo + '" id="' + id + '">' + celda_formateada(valor) + '</div>'
      end
    end
    # Si el parametro columna adicional es "suma" sumamos los valores de todas las columnas de la fila en la ultima columna
    clases[2] = "1_2_td" if otros[:sin_truncar]
    if otros[:columna_suma] 
      valor = suma_fila(datos, valores_fila["id"])
      rojo = (otros[:marcar_valores_negativos] and valor.is_a?(Numeric) and valor < 0) ? "texto_rojo" : ""
      fila << '<div class="elemento'+ clases[2]+' '+ rojo + '" id="' + id_fila + '_suma">' + celda_formateada(valor) + '</div>' 
    elsif otros[:columna_resta]
      valor = resta_fila(datos, valores_fila["id"])
      fila << '<div class="elemento'+ clases[2] +'" id="' + id_fila + '_resta">' + celda_formateada(valor)  + '</div>' 
    elsif otros[:columna_desviacion] 
      valor = desviacion_fila(datos, valores_fila["id"])
      fila << '<div class="elemento'+ clases[2] +'" id="' + id_fila + '_desviacion">' + celda_formateada(valor)  + '</div>' 
    elsif otros[:columna_pctparcial]
      valor = pctparcial_fila(datos, valores_fila["id"])
      fila << '<div class="elemento'+ clases[2] + '" id="' + id_fila + '_pctparcial">' + celda_formateada(valor) + ' %</div>' 
    elsif otros[:columna_porcentaje] 
      valor = porcentaje_fila(datos, valores_fila["id"])
      fila << '<div class="elemento'+ clases[2] +'" id="' + id_fila + '_porcentaje">' + celda_formateada(valor)  + ' %</div>' 
    end
    fila << '<div class = "linea"></div></div>'
  end
  
  # Metodo que devuelve el valor de un dato dada una matriz de datos y el id de columna y de fila.
  def valor_dato datos, fila_id, columna_id 
    valor = datos.detect {|v| v["columna_id"].to_s == columna_id.to_s and v["fila_id"].to_s == fila_id.to_s}
    valor = datos.detect {|v| v["columna_id"].to_s == columna_id.to_s and v["fila_id"].nil?} unless fila_id
    return  (valor ? valor["importe"] : 0)
  end

  def suma_fila datos, id
    total = datos.inject(0){|suma,d|  d["fila_id"].to_s == id.to_s ? suma + d["importe"].to_f : suma }
    return total ? total : 0
  end
  
  def fila_vacia datos, id
     return (datos.find {|d|  d["fila_id"].to_s == id.to_s } ? false : true)
  end

  def porcentaje_fila datos, id
    total = datos.inject(0){|suma,d|  d["fila_id"].to_s == id.to_s ? suma + d["importe"].to_f : suma }
    total ||= 0
    return @suma_total != 0 ? ((total/@suma_total) * 100) : 0
  end

  def resta_fila datos, id
    uno = (datos.detect {|v| v["columna_id"].to_s == "1" and v["fila_id"].to_s == id.to_s} || {"importe" => "0"} ).fetch("importe") 
    dos = (datos.detect {|v| v["columna_id"].to_s == "2" and v["fila_id"].to_s == id.to_s} || {"importe" => "0"} ).fetch("importe")
    total = uno.to_f - dos.to_f
    return total ?  total : 0
  end 

  def desviacion_fila datos, id
    uno = (datos.detect {|v| v["columna_id"].to_s == "1" and v["fila_id"].to_s == id.to_s} || {"importe" => "0"} ).fetch("importe")
    dos = (datos.detect {|v| v["columna_id"].to_s == "2" and v["fila_id"].to_s == id.to_s} || {"importe" => "0"} ).fetch("importe")
    calculo = ( uno && uno.to_f != 0 ) ? 100 * (uno.to_f - dos.to_f) / uno.to_f : "-" 
    return calculo
  end 

  def pctparcial_fila datos, id
    uno = (datos.detect {|v| v["columna_id"].to_s == "1" and v["fila_id"].to_s == id.to_s} || {"importe" => "0"} ).fetch("importe")
    dos = (datos.detect {|v| v["columna_id"].to_s == "2" and v["fila_id"].to_s == id.to_s} || {"importe" => "0"} ).fetch("importe")
    calculo = ( uno && uno.to_f != 0 ) ? 100 * dos.to_f / uno.to_f : "-"
    return calculo
  end
    
  def fila_suma_columnas datos, columnas, clases, otros
    rotulo_totales =_('TOTALES') + (otros[:tipo] ? ( " " + otros[:tipo].upcase) : "")
    rotulo_totales = "<i>" + rotulo_totales + "</i>" if otros[:tipo]
    cadena = '<div class = "fila texto_gris ' + clases[0] + '"' + @ancho_fila + ' id="fila_suma"><div class="elemento'+clases[1]+'">' + rotulo_totales + '</div>'
    diferencia = nil
    suma = 0
    for columna in columnas
      id = "celda_suma_"+ (otros[:tipo] ? (otros[:tipo] + "_") : "") + columna["id"].to_s 
      if otros[:tipo]
        # Si se le pasa el parametro tipo solo suma las columnas cuyo tipo coincida con el tipo pasado
        # Esto se utiliza de momento solo para la suma de partidas de tipo directo e indirecto
        total = datos.inject(0) do |suma,d|
          fila = otros[:filas].find{ |f| f["id"] == d["fila_id"]}
          tipo_correcto = fila ? fila["tipo"] == otros[:tipo] : false
          columna_correcta = d["columna_id"].to_s == columna["id"].to_s
          (columna_correcta and d["fila_id"] != nil and tipo_correcto) ? suma + d["importe"].to_f : suma
        end
      else
        total = datos.inject(0) do |suma,d|  
          (d["columna_id"].to_s == columna["id"].to_s and d["fila_id"] != nil) ? suma + d["importe"].to_f : suma 
        end
      end
      # Ponemos en rojo si esta pasada la propiedad marcar_valores_negativos y si es menor que cero
      rojo = (otros[:marcar_valores_negativos] and total.is_a?(Numeric) and total < 0) ? "texto_rojo" : ""
      cadena << '<div class="elemento'+ clases[2] +' '+ rojo + '" id="' + id + '">'
      cadena << (total ? number_with_delimiter(('%.2f' % total ).to_s , :separator => ",", :delimiter => ".") : "&nbsp;")
      diferencia = (diferencia ? diferencia - total : total) if otros[:columna_resta] or otros[:columna_pctparcial] 
      suma += total if otros[:columna_suma] or otros[:columna_pctparcial]
      cadena << '</div>'
    end
    clases[2] = clases[2] ||  "1_2_td" if otros[:sin_truncar]
    (cadena << '<div class="elemento'+ clases[2] +'" id="fila_suma_'+ ( otros[:tipo] ? (otros[:tipo] + "_") : "" ) +'suma">' + celda_formateada(suma) + '</div>') if otros[:columna_suma]
    (cadena << '<div class="elemento'+ clases[2] +'" id="fila_suma_'+ ( otros[:tipo] ? (otros[:tipo] + "_") : "" ) +'resta">' + celda_formateada(diferencia) + '</div>') if otros[:columna_resta]
    if otros[:columna_pctparcial]
      calculo = ( (suma + diferencia) != 0 ) ? 100 * (suma - diferencia) / (suma + diferencia) : "-"
      cadena << '<div class="elemento'+ clases[2] + '" id="fila_suma_pctparcial">' + celda_formateada(calculo) + ' %</div>' 
    end
    
    clases[2] = clases[2] ||  "2_3_td" if otros[:sin_truncar]
    #(cadena << '<div class="elemento'+ clases[2] +'" id="fila_suma_porcentaje">' + number_with_delimiter(('%.2f' % @suma_total ).to_s , :separator => ",", :delimiter => ".") + '</div>') if otros[:fila_porcentaje] or otros[:columna_porcentaje]
    cadena << '<div class = "linea"></div></div>'
    return cadena  
  end

  def fila_porcentaje_columnas datos, columnas, clases   
    cadena = '<div class = "fila'+clases[0]+'"'+ @ancho_fila +' id="fila_porcentaje"><div class="elemento'+clases[1]+'">' + _('PORCENTAJES') + '</div>'
    for columna in columnas
      id = "celda_porcentaje_" + columna["id"].to_s
      cadena << '<div class="elemento'+ clases[2] +'" id="' + id + '">'
      total = datos.inject(0){|suma,d|  (d["columna_id"] == columna["id"] and d["fila_id"] != nil) ? suma + d["importe"].to_f : suma} 
      porcentaje = @suma_total != 0 ? (total / @suma_total) * 100 : 0
      cadena << (total ? number_with_delimiter(('%.2f' % porcentaje ).to_s , :separator => ",", :delimiter => ".") : "&nbsp;")
      cadena << ' %</div>'
    end
    cadena << '<div class = "linea"></div></div>'  
    return cadena  
  end



end
