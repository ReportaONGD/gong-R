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
# Controlador encargado de la gestión de informes.


class InformeController < ApplicationController

  # La entrada redirecciona a la view seleccionar para seleccionar los criterios de importación.
  def index
    #@financiacion = @objeto = Financiacion.find(params[:financiacion_id])
    #@proyectos = @financiacion.proyecto
    redirect_to :action => 'seleccionar'
  end
  
  def seleccionar 

    # se envio desde el formulario criterios para forjar un fichero de salida
    if params[:selector]
      # incialización de las variables
      @proyecto_id = @proyecto.id.to_s
      tipo = params[:selector][:tipo]
      #config = Rails::Configuration.new
      db_config_file = ENV['GOR_SITEID'] ? ENV['RAILS_ETC'] + '.database.yml' : Rails::Configuration.new.database_configuration_file
      ejecutable_python = ENV['GONG_PYTHON'] + "crea_informe.py"

      case tipo
        when "informe_aecid"
          then
            xml_informe = ENV['GONG_PYTHON'] + "informe_aecid.xml"
            mimetype = "application/vnd.oasis.opendocument.spreadsheet"
            extension = "ods"
      end

      # variable para definir los paths temporales
      path = "#{ENV['RAILS_VAR']}/informe." + request.session_options[:id] + "."

      fichero_salida = path + tipo + ".xls"

      # Comprueba que exista el python de generacion de informes
      if File.exists?(ejecutable_python)
        system("python " + ejecutable_python + " " + @proyecto_id + " " + xml_informe + " " + fichero_salida + " " + db_config_file + " " + ENV['RAILS_ENV'] )

        # Comprueba que se haya generado el fichero de salida
        if File.exists?(fichero_salida)
          send_file fichero_salida, 
            :disposition => 'attachment',
            :type => mimetype,
            :encoding => 'utf8',
            :filename => "gong_" + tipo + "." + extension
          # Elimina los ficheros temporales para no dejarlo sucio (no se puede borrar aqui)
          #File.delete (fichero_salida)
        else
          msg_error _("Error en la generación del informe. Contacte con el administrador del sistema.")
        end
      else
        msg_error _("No está instalado el módulo de generación de informes. Contacte con el administrador del sistema.")
      end

    end
  end
end
