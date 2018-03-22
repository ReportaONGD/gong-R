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
# Reune metodos privados comunes a los controladores donde se realizan importaciones de XLS (importacion_controller y contabilidad_controller)

class BaseImportacionController < ApplicationController
  require 'spreadsheet'

  private
    def limpia_fila fila
      limpio = Array.new
      fila.each { |elemento| limpio.push( sanea elemento ) }
      fila.replace limpio
    end

    def sanea objeto
      #puts "-------------> OBJETO: " + objeto.inspect + " (" + objeto.class.name + ")"
      case objeto.class.name
        when "Spreadsheet::Excel::Error"
          return ""
          #puts "               Es un error"
        when "Spreadsheet::Formula"
          #puts "               Es una formula"
          return objeto.value
        else
          #puts "               Es un valor"
          return objeto
      end
    end

    def numero objeto
      valor = sanea(objeto)
      begin
        return valor.to_f if valor
      rescue => ex
        logger.error ">>>>>>>>>>>> Error parseando numero: " + ex.message
        logger.info  "             " + valor.inspect
        return nil
      end
    end

    def fecha fecha
      # Averiguar porque le falla a Jaime
      #return Date.parse fecha
      #logger.info "---------> La clase de fecha es: " + fecha.class.name
      #logger.info "           " + fecha.inspect
      return nil if fecha.class.name == "Spreadsheet::Formula"
      begin
        return fecha.to_datetime unless fecha.class.name == "Spreadsheet::Formula"
      rescue => ex
        logger.error ">>>>>>>>>>>> Error parseando fecha: " + ex.message
        logger.info  "             " + fecha.inspect
        return nil
      end
    end

    def importacion_error objeto, detalle=nil
      @import_error = "" unless @import_error
      if objeto.class == String
        @import_error << objeto + "<br>"
      else
        if !objeto.errors.empty?
          @import_error << "<br>" + _("Se produjeron errores procesando") + " " + (detalle ? detalle.to_s : objeto.class.name) + ":<br>"
          objeto.errors.each {|a, m| @import_error += m + "<br>" }
        end
      end
    end

end
