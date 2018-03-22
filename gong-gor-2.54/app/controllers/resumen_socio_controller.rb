# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed, CENATIC y IEPALA
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
# Controlador encargado de las vistas resumen de socio. Este controlador es utilizado desde la seccion de socios.

class ResumenSocioController < ApplicationController

  def index
    redirect_to :action => :categorias
  end

  # Resumen de socios por categorias
  def categorias 
    @socios_sexo = Socio.count(:id, :group => 'sexo')
    @socios_naturaleza_socio = Socio.count(:id, :group => 'naturaleza', :joins => "LEFT OUTER JOIN `naturaleza_socio` ON naturaleza_socio.id = socio.naturaleza_socio_id" )
    @socios_provincia = Socio.count(:id, :group => 'provincia')
    @socios_tipo_cuota = Socio.count(:id,  :group => 'tipo_cuota', :joins => "LEFT OUTER JOIN `informacion_socio` ON informacion_socio.socio_id = socio.id LEFT OUTER JOIN `tipo_cuota_socio` ON informacion_socio.tipo_cuota_socio_id = tipo_cuota_socio.id ")
    @socios_edad = Array.new
       for n in 1..10
            fecha_fin = Time.now.years_ago((n -1) * 10)
            fecha_inicio = Time.now.years_ago(n * 10)
            cantidad = Socio.count :all, :conditions => {"fecha_nacimiento" => (fecha_inicio.to_date)..(fecha_fin.to_date) }
            @socios_edad.push [((n -1) * 10).to_s + " - " + (n * 10).to_s, cantidad]
       end
    fecha_fin = Time.now.years_ago(100)
    fecha_inicio = Time.now.years_ago(1000)
    cantidad = Socio.count :all, :conditions => {"fecha_nacimiento" => (fecha_inicio.to_date)..(fecha_fin.to_date) }
    @socios_edad.push [" > " + (n * 10).to_s, cantidad]
  end

  # Generacion del modelo 182
  def modelo_182
    # Si hemos definido un año y es posterior a 1999
    if params[:ejercicio] && params[:ejercicio].to_i > 1999
      @anno = params[:ejercicio]
      # Fechas inicio y fin de los pagos a obtener
      fecha_inicio = Date.new(@anno.to_i,1,1)
      fecha_fin = fecha_inicio.next_year - 1.day 
      # Generamos el modelo 182 y lo devolvemos si todo ha ido ok
      ###### CODIGO #######
      # Mostramos el error indicando el problema si algo ha ido mal
      #msg_error( _("Ha ocurrido un error inesperado.") )
    end
  end
end

