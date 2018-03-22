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
class ValorVariableIndicador < ActiveRecord::Base
  belongs_to :variable_indicador
  #untranslate_all
  validates_presence_of :valor, :message => _("El valor medido") + " " + _("no puede estar vacío.")
  validates_presence_of :fecha, :message => _("La fecha") + " " + _("no puede estar vacía.")

  validate :comprueba_fechas

  def comprueba_fechas
    if variable_indicador && (variable_indicador.indicador.proyecto.fecha_de_inicio > self.fecha || variable_indicador.indicador.proyecto.fecha_de_fin < self.fecha)
      errors.add( "etapa", _("La fecha está fuera del proyecto."))
      return false
    end
  end

end

