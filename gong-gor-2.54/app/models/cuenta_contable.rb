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
# cuenta contable 

class CuentaContable < ActiveRecord::Base
  # Esto nos permite obtener el elemento (proyecto, agente, ...)  haciendo codigo_contable.contabilidad
  belongs_to :elemento_contable, polymorphic: true
  # Esta es la delegacion a la que pertenecen los codigos contables
  belongs_to :delegacion, :class_name => "Agente", :foreign_key => "agente_id"

  # Para poder hacer joins...
  scope :by_type, lambda { |type| joins("JOIN #{type.table_name} ON #{type.table_name}.id = #{CuentaContable.table_name}.elemento_contable_id AND #{CuentaContable.table_name}.elemento_contable_type = '#{type.to_s}'") }

  validates_presence_of :codigo, :message => _("Código") + " " + _("no puede estar vacío.")
  validates_presence_of :elemento_contable_type, :message => _("Tipo de subcuenta") + " " + _("no puede estar vacío."), :if => :segun_plugin_activo
  # Dejamos la validacion de codigo unico para cada delegacion en el plugin de aps (el de oei requiere que puedan duplicarse)
  #validates_uniqueness_of :codigo, :scope => [:agente_id,:centro_coste], :message => _("Código repetido.")

  # Hace validaciones particulares segun los plugins usados
  validate :verificar_condiciones_plugins

  def esta_vinculado?
    return !elemento_contable.nil?
  end

 private

  # Validaciones particulares segun los plugins usados
  def verificar_condiciones_plugins
    Plugin.activos.each do |plugin|
      begin
        eval(plugin.clase + "::CuentaContable").verificar_condiciones self
      rescue => ex
        #logger.info "-----------> ERROR (CuentaContable.verificar_condiciones_plugins): " + ex.inspect
      end
    end
    return self.errors.empty?
  end
  
  # Si el plugin cpt_contabilidad esta activo no se necesita tipo de subcuenta
  # OJO: Quiza para mantener coherencia la validacion del tipo de subcuenta deberia trasladarse a los plugin con el metodo anterior "verficar_condicions_plugins"... pero no quiero tocar en los otros plugins.
  def segun_plugin_activo
    Plugin.activos.find {|p| p.codigo == "cpt_contabilidad"} ? false : true
  end
  
end
