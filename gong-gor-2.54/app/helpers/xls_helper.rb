# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2014 Free Software's Seed, CENATIC y IEPALA
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
# Helpers para exportaciones a XLS 

module XlsHelper

  # Listado de colores XLS: http://www.softwaremaniacs.net/2013/11/setting-cell-color-using-ruby.html
  def formato_xls_negrita
    return Spreadsheet::Format.new :weight => :bold, :align => :top, :text_wrap => true, :number_format => '#,##0.00'
  end
  def formato_xls_negrita_centrado
    return Spreadsheet::Format.new :weight => :bold, :align => :top, :text_wrap => true, :number_format => '#,##0.00', :horizontal_align=>:center
  end
  def formato_xls_normal
    return Spreadsheet::Format.new valores_formato_xls_normal
  end
  def formato_xls_cabecera
    return Spreadsheet::Format.new :weight => :bold, :align => :middle, :pattern => 1, :pattern_fg_color => :aqua, :number_format => '#,##0.00'
  end
  def formato_xls_centrado_activado
    return Spreadsheet::Format.new :text_wrap => true, :align => :middle, :number_format => '#,##0.00', :horizontal_align=>:center, :pattern => 1, :pattern_fg_color => :silver
  end
  def formato_xls_centrado_resaltado
    return Spreadsheet::Format.new :text_wrap => true, :align => :middle, :number_format => '#,##0.00', :horizontal_align=>:center, :pattern => 1, :pattern_fg_color => :green
  end
  def valores_formato_xls_normal
    { :text_wrap => true, :align => :top, :number_format => '#,##0.00' }
  end
  def formato_xls_personalizado xls_format
    xls_format ||= {}
    xls_format.delete(:pattern_fg_color) if xls_format[:pattern_fg_color].blank?
    xls_format[:number_format] ||= '#,##0.00'
    xls_format[:align] ||= :top
    xls_format[:pattern] ||= 1 if xls_format[:pattern_fg_color]
    return Spreadsheet::Format.new xls_format
  end

  def xls_resumen_listado workbook,listado
    #puts "--------> Entramos"
    unless hoja = workbook.worksheet(listado[:nombre])
      hoja = workbook.create_worksheet
      hoja.name = listado[:nombre] if listado[:nombre]
    end
    default_format = listado[:xls_default_format].blank? ? valores_formato_xls_normal : listado[:xls_default_format]
    hoja.default_format = formato_xls_personalizado default_format

    # Cabecera de la hoja
    fila = listado[:xls_title_row].blank? ? 0 : listado[:xls_title_row] 
    # Formato a aplicar para el titulo de la hoja
    title_format = listado[:xls_title_format].blank? ? formato_xls_cabecera : formato_xls_personalizado(listado[:xls_title_format])
    # Si no queremos combinar columnas para el titulo...
    if listado[:xls_title_cols].blank?
      # aplicamos a toda la linea el formato
      hoja.row(fila).default_format = title_format
    else
      # Queremos combinar: mezclamos de la 0 a la xls_title_cols -1 ...
      ultima_columna = listado[:xls_title_cols] - 1
      hoja.merge_cells(fila, 0, fila, ultima_columna)
      # ... y aplicamos el estilo a las columnas
      (0..ultima_columna).each {|col| hoja.row(fila).set_format(col, title_format) }
    end
    unless listado[:titulo] && listado[:titulo].class.name == "Array"
      hoja.row(fila).height = 25
      hoja[fila,0] = listado[:titulo] if listado[:titulo]
    else
      hoja.row(fila).height = (15 * listado[:titulo].size) + 10
      hoja[fila,0] = listado[:titulo].join("\n")
    end

    cabecera = Array.new
    fila += 2
   
    #puts "--------> Recorremos todas las lineas del listado" 
    for linea in listado[:lineas]
      #puts "          Analizamos: " + linea.inspect 
      columna = 0
      hoja.row(fila).height = 15
      if linea[:nivel_anidado]
        hoja.row(fila).outline_level = linea[:nivel_anidado] 
        hoja.row(fila).hidden = true if linea[:nivel_anidado]
      end
      if linea[:cabecera]
        hoja.row(fila).default_format = formato_xls_negrita
        linea[:cabecera].each do |elemento|
          hoja[fila,columna] = elemento[0]
          hoja.column(columna).width = caracteres(elemento[1])
          altura = 13 * (1 + elemento[0].to_s.size/caracteres(elemento[1]).to_i)
          hoja.row(fila).height = altura if altura > hoja.row(fila).height
          columna +=1
        end
        cabecera = linea[:cabecera]
      else
        # Recorre cada una de las columnas del contenido
        linea[:contenido].each_with_index do |elemento,index|
          # Si el elemento es un string o un "safe_buffer" (.html_safe) le quitamos los espacios html
          # (quizas deberiamos sustituir todos los caracteres html)
          elemento = elemento.gsub("&nbsp;"," ") if elemento.class.name == "ActiveSupport::SafeBuffer" || elemento.class.name == "String"
          estilo_elemento = (linea[:xls_format].blank? || elemento.nil?) ? default_format.dup : linea[:xls_format]
          hoja[fila,columna] = elemento
          # Averigua la anchura que debe tener
          # En primer lugar, busca si hay una definicion de anchuras y estilos
          if linea[:estilo] && linea[:estilo][index].is_a?(Array)
            estilo_elemento[:horizontal_align] = :right if linea[:estilo][index][1].end_with?("_td") || linea[:estilo][index][1].end_with?("_td_g")
            estilo_elemento[:horizontal_align] = :center if linea[:estilo][index][1].end_with?("_tc")
          end
          # Mira si tiene que aplicar autoanchura
          if linea[:autoanchura]
            # Ajusta la anchura de la columna si el elemento es mayor a la existente
            anchura_elemento = elemento.to_s.size + 5 
            hoja.column(columna).width = anchura_elemento if hoja.column(columna).width < anchura_elemento
          # ... o aumenta la altura ...
          else
            chars = cabecera && cabecera[columna] ? cabecera[columna][1] : "1"
            altura = 13 * (1 + elemento.to_s.size/caracteres(chars).to_i)
            hoja.row(fila).height = altura if altura > hoja.row(fila).height
          end
          # Por ultimo, aplica los estilos a usar si existen
          hoja.row(fila).set_format(columna, formato_xls_personalizado(estilo_elemento))
          # Pasa a la siguiente columna
          columna +=1
        end
      end
      fila+=1
    end
  end

  def xls_resumen_objeto workbook,objeto
    hoja = workbook.create_worksheet
    hoja.name = objeto[:titulo][0] if objeto[:titulo][0]

    hoja.default_format = formato_xls_normal
    hoja.row(0).height = 25

    fila = 0
    # Pone la cabecera
    objeto[:titulo].each do |linea_titulo|
      hoja.row(fila).default_format = formato_xls_cabecera
      hoja[fila,0] = linea_titulo
      fila += 1
    end

    fila += 1

    columna=0
    hoja.row(fila).default_format = formato_xls_negrita
    # Escribimos los nombres de las columnas
    campos = campos_listado(objeto[:tipo])
    campos += campos_info(objeto[:tipo]) if campos_info(objeto[:tipo])
    campos.each do |campo|
      hoja[fila,columna] = (campo[0]=="&nbsp;" ? "" : campo[0])
      hoja.column(columna).width = caracteres(campo[1])
      columna += 1;
    end
    # Mete las cabeceras de los campos de objetos dependientes
    objeto[:subobjetos].each do |subobjeto|
      campos_listado(subobjeto).each do |campo|
        hoja[fila,columna] = (campo[0]=="&nbsp;" ? "" : (campo[0] + " " + subobjeto.tr("_", " ").capitalize) )
        hoja.column(columna).width = caracteres(campo[1])
        columna += 1;
      end
    end if objeto[:subobjetos] 

    fila += 1

    # Mete cada uno de los elementos proporcionados
    objeto[:objetos].each do |obj|
      columna = 0
      fila_incremento = 1
      # Mete los campos del objeto que hay en el listado
      campos.each do |campo|
        valor = obj
        valor_real = ""
        campo[2].split('.').each do |metodo|
          valor = (metodo =~ /(\S+)\s(\S+)/ ? valor.send($1,$2) : valor.send(metodo)) if valor
        end
        if valor.class.to_s == "Array"
          saltos = 0
          valor.each do |v|
            valor_real += (valor_real=="" ? "" : "\n\r") + v
            saltos += 1
          end
          altura = 12 * saltos
        else
          valor_real = valor
          altura = 13 * (1 + valor_real.to_s.size/caracteres(campo[1]).to_i)
        end
        hoja[fila,columna] = valor_real
        hoja.row(fila).height = altura if altura > hoja.row(fila).height
        columna += 1
      end
      # Mete los campos de los subobjetos dependientes 
      objeto[:subobjetos].each do |subobjeto|
        elementos = obj
        subobjeto.split('.').each { |sub| elementos = elementos.send(sub) if elementos }
        elementos = [ elementos ] if elementos.class.name != "Array"
        #elementos = obj.send(subobjeto)
        fila_elemento = 0
        columna_elemento = columna
        # Recorre cada resultado del subobjeto relacionado
        elementos.each do |elemento|
          columna_elemento = columna
          # Y va dibujando cada campo
          campos_listado(subobjeto).each do |campo|
            valor = elemento
            campo[2].split('.').each do |metodo|
              valor = (metodo =~ /(\S+)\s(\S+)/ ? valor.send($1,$2) : valor.send(metodo)) if valor
            end
            hoja[fila_elemento+fila,columna_elemento] = valor
            altura = 13 * (1 + valor.to_s.size/caracteres(campo[1]).to_i)
            hoja.row(fila_elemento+fila).height = altura if altura > hoja.row(fila).height
            columna_elemento += 1
          end
          fila_elemento += 1
        end
        # Ajusta la columna y el incremento maximo que ha habido en filas
        columna = columna_elemento
        fila_incremento = fila_elemento if fila_elemento > fila_incremento
      end if objeto[:subobjetos]
      # Ajusta las filas segun el incremento maximo 
      fila += fila_incremento
    end

  end

  def xls_resumen_tabla workbook,tabla
    hoja = workbook.create_worksheet
    hoja.name = tabla[:titulo][0] if tabla[:titulo][0]

    hoja.default_format = formato_xls_normal
    hoja.row(0).height = 25

    fila = 0
    # Pone la cabecera
    tabla[:titulo].each do |linea_titulo|
      hoja.row(fila).default_format = formato_xls_cabecera
      hoja[fila,0] = linea_titulo
      fila += 1
    end

    fila += 1
    clases = tabla[:otros][:clases] || ["","3_2","1_td"]
    total = Hash.new

    columna=1
    hoja.row(fila).default_format = formato_xls_negrita
    hoja.column(0).width = caracteres(clases[2])
    # Escribimos los nombres de las columnas
    tabla[:columnas].each do |data_columna|
      hoja[fila,columna] = data_columna["nombre"]
      hoja.column(columna).width = caracteres(clases[2])
      altura = 13 * (1 + data_columna["nombre"].to_s.size/caracteres(clases[2]).to_i)
      hoja.row(fila).height = altura if altura > hoja.row(fila).height
      columna +=1
    end

    texto_columna_suma =       tabla[:otros][:columna_suma] == true       ? _('Totales')      : tabla[:otros][:columna_suma].to_s
    texto_columna_resta =      tabla[:otros][:columna_resta] == true      ? _('Diferencia')   : tabla[:otros][:columna_resta].to_s
    texto_columna_desviacion = tabla[:otros][:columna_desviacion] == true ? _('% Desviacion') : tabla[:otros][:columna_desviacion].to_s
    texto_columna_pctparcial = tabla[:otros][:columna_pctparcial] == true ? _('% Realizado')  : tabla[:otros][:columna_pctparcial].to_s
    texto_columna_porcentaje = tabla[:otros][:columna_porcentaje] == true ? _('Porcentaje')   : tabla[:otros][:columna_porcentaje].to_s
    hoja[fila,columna] = texto_columna_suma if tabla[:otros][:columna_suma]
    hoja.column(columna).width = caracteres(clases[2])
    columna += 1 if tabla[:otros][:columna_suma]
    hoja[fila,columna] = texto_columna_resta if tabla[:otros][:columna_resta]
    hoja.column(columna).width = caracteres(clases[2])
    columna += 1 if tabla[:otros][:columna_resta]
    hoja[fila,columna] = texto_columna_desviacion if tabla[:otros][:columna_desviacion]
    hoja.column(columna).width = caracteres(clases[2])
    columna += 1 if tabla[:otros][:columna_desviacion]
    hoja[fila,columna] = texto_columna_pctparcial if tabla[:otros][:columna_pctparcial]

    # Escribimos el contenido de la tabla
    fila+=1
    for data_fila in tabla[:filas]
      fila_id = data_fila["id"]
      hoja[fila,0] = data_fila["nombre"]
      altura = 13 * (1 + data_fila["nombre"].to_s.size/caracteres(clases[2]).to_i)
      hoja.row(fila).height = altura if altura > hoja.row(fila).height
      columna=1
      suma = 0
      for data_columna in tabla[:columnas]
        columna_id = data_columna["id"]
        valor = valor_dato(tabla[:datos], fila_id, columna_id)
        hoja[fila,columna] = valor
        total[columna] ||= 0 if tabla[:otros][:fila_suma]
        total[columna] += valor.to_f if valor && tabla[:otros][:fila_suma]
        columna +=1
      end

      hoja[fila,columna] = suma_fila(tabla[:datos],fila_id) if tabla[:otros][:columna_suma]
      columna +=1 if tabla[:otros][:columna_suma]
      hoja[fila,columna] = resta_fila(tabla[:datos], fila_id) if tabla[:otros][:columna_resta]
      columna +=1 if tabla[:otros][:columna_resta]
      hoja[fila,columna] = desviacion_fila(tabla[:datos], fila_id) if tabla[:otros][:columna_desviacion]
      columna +=1 if tabla[:otros][:columna_desviacion]
      hoja[fila,columna] = pctparcial_fila(tabla[:datos], fila_id) if tabla[:otros][:columna_pctparcial]
      columna +=1 if tabla[:otros][:columna_pctparcial]
      fila +=1
    end

    # Escribimos la fila de totales
    hoja[fila,0] = _("TOTALES") if tabla[:otros][:fila_suma]
    total.each do |k,v|
      hoja[fila,k] = v
    end if tabla[:otros][:fila_suma]
  end

end
