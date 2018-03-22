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
class ActividadDetallada < ActiveRecord::Base
  #untranslate_all
  belongs_to :etapa
  belongs_to :actividad

  # Metodo creado para el WS
  # Devuelve el mes relativo a la etapa en mes relativo al proyecto
  def mes_proyecto
    return ((etapa.fecha_inicio.month) - etapa.proyecto.fecha_de_inicio.month) + (12 * (etapa.fecha_inicio.year - etapa.proyecto.fecha_de_inicio.year)) + mes
  end
end
