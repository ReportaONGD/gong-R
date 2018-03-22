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
# Mediciones de cumplimiento de Indicadores 

# Gestiona el modelo ValorIntermedioXIndicador.
class ValorIntermedioXIndicador < ActiveRecord::Base
  #untranslate_all
  belongs_to :indicador
  belongs_to :usuario
  validates_presence_of :indicador_id, :message => _("Indicador") + " " + _("no puede estar vacío.")
  validates_presence_of :porcentaje, :message => _("Porcentaje") + " " + _("no puede estar vacío.")
  validates_presence_of :fecha, :message => _("Fecha") + " " + _("no puede estar vacía.")

  validate :comprueba_fechas

  def comprueba_fechas
    if self.fecha.nil? || indicador.proyecto.fecha_de_inicio > self.fecha || indicador.proyecto.fecha_de_fin < self.fecha
      errors.add( "etapa", _("La fecha está fuera del proyecto."))
      return false
    end
  end

end
