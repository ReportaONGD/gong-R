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
# GastoXAgente : recoge la relacion entre gasto y agente financiador con porcentaje.
class GastoXAgente < ActiveRecord::Base

  # Metemos la validacion antes para que no se eliminen gxp de proyectos cerrados
  before_destroy :verifica_borrado
  before_destroy :comprobar_estado_proyecto, :comprobar_periodos_proyecto, :verifica_plugins

  #untranslate_all
  belongs_to :gasto
  belongs_to :agente
  belongs_to :proyecto

  validates_presence_of :agente_id, :message => _("Financiador") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :agente_id, :scope => [:gasto_id, :proyecto_id], :message => _("Financiador repetido.")
  validates_presence_of :importe, :message => _("Importe") + " " + _("no puede estar vacío.")
  # Permitimos gastos negativos para aceptar devoluciones
  #validates_numericality_of :importe, :greater_than => 0, :message => _("Importe para el financiador") + " " + _("no puede estar vacío.")

  validate :comprobar_estado_proyecto, :comprobar_periodos_proyecto, :comprobar_financiador_proyecto, :verifica_plugins

  # Para que los plugins puedan modificar saltandose la validacion "verifica_plugins"
  # OJO!: Siempre que se hagan movimientos en los gastos desde migraciones hay que tener en cuenta esto y
  #       actualizar el gasto incluyendo "evitar_validacion_plugins: true"!
  attr_accessor :evitar_validacion_plugins

  # Comprueba que el estado del proyecto para el que se esta modificando el GastoXAgente
  def comprobar_estado_proyecto
    errors.add(_("Proyecto"),  _("El proyecto '%{proy}' se encuentra en estado '%{est}'.")%{proy: proyecto.nombre, est: proyecto.estado_actual.definicion_estado.nombre} + " " +
                               _("En este estado no se puede modificar el gasto.")) if proyecto && proyecto.estado_actual && !proyecto.estado_actual.definicion_estado.ejecucion
    return errors.empty?  
  end

  def comprobar_periodos_proyecto
    for periodo in proyecto.periodo
      if periodo.gastos_cerrados and (gasto.fecha >= periodo.fecha_inicio and gasto.fecha <= periodo.fecha_fin) 
        texto = _("El gasto está asociado al proyecto '%{proy}'.")%{ proy: proyecto.nombre } + 
                _("El periodo de justificación: %{per} ( + %{inicio}  / + %{fin}) tiene los gastos cerrados y no se puede modificar el gasto.")%{per: periodo.tipo_periodo.nombre, inicio: periodo.fecha_inicio.to_s , fin: periodo.fecha_fin.to_s }
        errors.add(_("Proyecto"), texto) 
      end
    end if proyecto
    return errors.empty?
  end

  # Comprueba que el fianciador del gasto este asignado en el proyecto
  def comprobar_financiador_proyecto
    errors.add :base, _("El financiador '%{agt}' no está asignado al proyecto '%{proy}'.")%{agt: agente.nombre, proy: proyecto.nombre} if proyecto && proyecto.financiador.exclude?(agente)
    return errors.empty?
  end

 private

  # Agrupa todas las validaciones para el borrado anteponiendo una variable de clase que permita saber que estamos antes de un borrado
  def verifica_borrado
    @eliminando_gasto = true
    # Agrupamos todos con AND para que el solo se devuelva true si todos devuelven true
    return ( comprobar_estado_proyecto && comprobar_periodos_proyecto && verifica_plugins )
  end

  # Verifica que los plugins permitan la edicion
  # OJO!: Siempre que se hagan movimientos en los gastos desde migraciones hay que tener en cuenta esto!
  def verifica_plugins
    Plugin.activos.each do |plugin|
      begin
        eval(plugin.clase + "::GastoXAgente").verifica self, @eliminando_gasto
      rescue => ex
      end
    end unless self.evitar_validacion_plugins || (self.changed.empty? && @eliminando_gasto.nil?)
    return self.errors.empty?
  end


end
