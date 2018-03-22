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
# etiqueta tecnica 
class EtiquetaTecnica < ActiveRecord::Base
  has_many :actividad_x_etiqueta_tecnica, :dependent => :destroy
  has_many :actividad, :through => :actividad_x_etiqueta_tecnica, :uniq => true

  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")

  def porcentaje_x_actividad actividad_id=nil
    axet=actividad_x_etiqueta_tecnica.find_by_proyecto_id(actividad_id)
    return axet ? axet.porcentaje : 0
  end

end
#done
