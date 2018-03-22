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
# actividad de la matriz

# Gestiona el modelo actividad.
class Subactividad < ActiveRecord::Base
  #untranslate_all
  belongs_to :actividad
  has_many :comentario, as: :elemento, dependent: :destroy
  has_many :valor_intermedio_x_subactividad, :order => "fecha DESC", :dependent => :destroy
  has_many :subactividad_detallada, :dependent => :destroy
  validates_presence_of :descripcion, :message => _("Descripción") + " " + _("no puede estar vacía.")

  def estado_actual
    return valor_intermedio_x_subactividad.first
  end

  def porcentaje_actual
    return estado_actual ? estado_actual.porcentaje : 0.0
  end

end
