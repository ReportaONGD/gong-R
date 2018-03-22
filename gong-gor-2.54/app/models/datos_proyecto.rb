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
# datos de proyecto

class DatosProyecto < ActiveRecord::Base
  belongs_to :proyecto
  belongs_to :pais

  validates_uniqueness_of :pais_id, scope: [:proyecto_id], message: _("País ya asignado")

  # Metodos de agrupacion para mostrar en listados
  def directos
    (beneficiarios_directos_hombres||0) + (beneficiarios_directos_mujeres||0) + (beneficiarios_directos_sin_especificar||0)
  end
  def indirectos
    (beneficiarios_indirectos_hombres||0) + (beneficiarios_indirectos_mujeres||0) + (beneficiarios_indirectos_sin_especificar||0)
  end
end
