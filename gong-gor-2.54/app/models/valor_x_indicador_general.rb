# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2017 OEI, Free Software's Seed
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
# Mediciones de cumplimiento de Indicadores Generales

# Gestiona el modelo ValorXIndicadorGeneral.
class ValorXIndicadorGeneral < ActiveRecord::Base
  belongs_to :indicador_general_x_proyecto
  validates_presence_of :valor, :message => _("Valor medido") + " " + _("no puede estar vacío.")
  validates_presence_of :fecha, :message => _("Fecha") + " " + _("no puede estar vacía.")

  validate :comprueba_fechas

  def comprueba_fechas
    if fecha && indicador_general_x_proyecto && 
       (indicador_general_x_proyecto.proyecto.fecha_de_inicio > fecha ||
        indicador_general_x_proyecto.proyecto.fecha_de_fin < fecha)
      errors.add :base, _("La fecha está fuera del proyecto.")
    end
    return errors.empty?
  end

end
